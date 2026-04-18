#!/usr/bin/env python3
"""
ORB Telegram Bridge
-------------------
Run this on your PC or any always-on device.
This connects your Telegram bot to the same AI model ORB uses.

Usage:
    python bot.py --token YOUR_BOT_TOKEN --provider claude --apikey YOUR_API_KEY

Requirements:
    pip install python-telegram-bot anthropic openai google-generativeai
"""

import argparse
import asyncio
import logging
import os
from typing import Optional

import anthropic
import openai
from telegram import Update
from telegram.ext import (
    Application,
    CommandHandler,
    ContextTypes,
    MessageHandler,
    filters,
)

# ─── Logging ────────────────────────────────────────────────────────────────

logging.basicConfig(
    format="%(asctime)s | %(levelname)s | %(message)s",
    level=logging.INFO,
)
logger = logging.getLogger(__name__)

# ─── In-memory conversation history ─────────────────────────────────────────

# chat_id → list of {role, content} dicts
conversation_history: dict[int, list[dict]] = {}
MAX_HISTORY = 10

# ─── System prompt ───────────────────────────────────────────────────────────

SYSTEM_PROMPT = """You are ORB (On-screen Reasoning Brain), a smart personal AI assistant. 
You are running as a Telegram bot bridge. Be helpful, concise, and friendly.
Format responses cleanly — Telegram supports basic markdown."""


# ─── AI Providers ────────────────────────────────────────────────────────────


def chat_claude(messages: list[dict], api_key: str, model: str) -> str:
    client = anthropic.Anthropic(api_key=api_key)
    response = client.messages.create(
        model=model,
        max_tokens=1024,
        system=SYSTEM_PROMPT,
        messages=messages,
    )
    return response.content[0].text


def chat_openai(messages: list[dict], api_key: str, model: str) -> str:
    client = openai.OpenAI(api_key=api_key)
    full_messages = [{"role": "system", "content": SYSTEM_PROMPT}] + messages
    response = client.chat.completions.create(
        model=model,
        max_tokens=1024,
        messages=full_messages,
    )
    return response.choices[0].message.content


def chat_gemini(messages: list[dict], api_key: str, model: str) -> str:
    try:
        import google.generativeai as genai
        genai.configure(api_key=api_key)
        gemini_model = genai.GenerativeModel(
            model_name=model,
            system_instruction=SYSTEM_PROMPT,
        )
        # Convert to Gemini format
        history = []
        for msg in messages[:-1]:
            history.append({
                "role": "model" if msg["role"] == "assistant" else "user",
                "parts": [msg["content"]],
            })
        chat = gemini_model.start_chat(history=history)
        response = chat.send_message(messages[-1]["content"])
        return response.text
    except ImportError:
        return "⚠️ google-generativeai not installed. Run: pip install google-generativeai"


def get_ai_response(
    messages: list[dict],
    provider: str,
    api_key: str,
    model: Optional[str],
) -> str:
    defaults = {
        "claude": "claude-sonnet-4-5",
        "openai": "gpt-4o-mini",
        "gemini": "gemini-1.5-flash",
    }
    chosen_model = model or defaults.get(provider, "")

    try:
        if provider == "claude":
            return chat_claude(messages, api_key, chosen_model)
        elif provider == "openai":
            return chat_openai(messages, api_key, chosen_model)
        elif provider == "gemini":
            return chat_gemini(messages, api_key, chosen_model)
        else:
            return f"⚠️ Unknown provider: {provider}"
    except Exception as e:
        logger.error(f"AI error: {e}")
        return f"⚠️ Error: {str(e)}"


# ─── Telegram Handlers ───────────────────────────────────────────────────────


async def start(update: Update, context: ContextTypes.DEFAULT_TYPE) -> None:
    chat_id = update.effective_chat.id
    conversation_history[chat_id] = []
    await update.message.reply_text(
        "👁️ *ORB is online*\n\nI'm your On-screen Reasoning Brain, now on Telegram.\n\nAsk me anything!",
        parse_mode="Markdown",
    )


async def clear(update: Update, context: ContextTypes.DEFAULT_TYPE) -> None:
    chat_id = update.effective_chat.id
    conversation_history[chat_id] = []
    await update.message.reply_text("🗑️ Conversation cleared.")


async def help_cmd(update: Update, context: ContextTypes.DEFAULT_TYPE) -> None:
    await update.message.reply_text(
        "*ORB Telegram Bridge*\n\n"
        "/start — Start or restart conversation\n"
        "/clear — Clear conversation history\n"
        "/status — Check bot status\n"
        "/help — Show this message\n\n"
        "Just type any message to chat with ORB!",
        parse_mode="Markdown",
    )


async def status(update: Update, context: ContextTypes.DEFAULT_TYPE) -> None:
    provider = context.bot_data.get("provider", "unknown")
    model = context.bot_data.get("model", "default")
    await update.message.reply_text(
        f"✅ *ORB is running*\n\nProvider: `{provider}`\nModel: `{model}`",
        parse_mode="Markdown",
    )


async def handle_message(
    update: Update, context: ContextTypes.DEFAULT_TYPE
) -> None:
    chat_id = update.effective_chat.id
    user_text = update.message.text

    if chat_id not in conversation_history:
        conversation_history[chat_id] = []

    # Add user message to history
    conversation_history[chat_id].append(
        {"role": "user", "content": user_text}
    )

    # Trim history
    if len(conversation_history[chat_id]) > MAX_HISTORY * 2:
        conversation_history[chat_id] = conversation_history[chat_id][
            -MAX_HISTORY * 2 :
        ]

    # Show typing indicator
    await context.bot.send_chat_action(
        chat_id=chat_id, action="typing"
    )

    # Get AI response
    provider = context.bot_data.get("provider", "claude")
    api_key = context.bot_data.get("api_key", "")
    model = context.bot_data.get("model", None)

    response = await asyncio.get_event_loop().run_in_executor(
        None,
        get_ai_response,
        conversation_history[chat_id].copy(),
        provider,
        api_key,
        model,
    )

    # Add assistant response to history
    conversation_history[chat_id].append(
        {"role": "assistant", "content": response}
    )

    # Send response (split if too long for Telegram's 4096 char limit)
    if len(response) > 4000:
        chunks = [response[i : i + 4000] for i in range(0, len(response), 4000)]
        for chunk in chunks:
            await update.message.reply_text(chunk)
    else:
        try:
            await update.message.reply_text(response, parse_mode="Markdown")
        except Exception:
            # Fallback without markdown if parsing fails
            await update.message.reply_text(response)


# ─── Main ────────────────────────────────────────────────────────────────────


def main():
    parser = argparse.ArgumentParser(description="ORB Telegram Bridge")
    parser.add_argument(
        "--token",
        required=True,
        help="Telegram bot token from @BotFather",
    )
    parser.add_argument(
        "--provider",
        choices=["claude", "openai", "gemini"],
        default="claude",
        help="AI provider to use",
    )
    parser.add_argument(
        "--apikey",
        required=True,
        help="API key for the selected AI provider",
    )
    parser.add_argument(
        "--model",
        default=None,
        help="Override model (optional). Defaults: claude-sonnet-4-5 / gpt-4o-mini / gemini-1.5-flash",
    )
    args = parser.parse_args()

    logger.info(f"Starting ORB Telegram Bridge | provider={args.provider}")

    app = Application.builder().token(args.token).build()

    # Store config in bot_data
    app.bot_data["provider"] = args.provider
    app.bot_data["api_key"] = args.apikey
    app.bot_data["model"] = args.model

    # Register handlers
    app.add_handler(CommandHandler("start", start))
    app.add_handler(CommandHandler("clear", clear))
    app.add_handler(CommandHandler("help", help_cmd))
    app.add_handler(CommandHandler("status", status))
    app.add_handler(
        MessageHandler(filters.TEXT & ~filters.COMMAND, handle_message)
    )

    logger.info("ORB Telegram Bridge is running. Press Ctrl+C to stop.")
    app.run_polling(allowed_updates=Update.ALL_TYPES)


if __name__ == "__main__":
    main()
