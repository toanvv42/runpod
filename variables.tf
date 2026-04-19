variable "runpod_api_key" {
  type      = string
  sensitive = true
}

variable "ollama_model" {
  type        = string
  default     = "gemma4:31b"
  description = "Ollama model tag to pull (e.g. gemma4:31b, gemma4:26b)"
}

variable "use_spot" {
  type        = bool
  default     = true
  description = "Use spot instances to reduce cost"
}

variable "telegram_bot_token" {
  type        = string
  default     = ""
  sensitive   = true
  description = "Optional Telegram bot token used to send the deployment notification"
}

variable "telegram_chat_id" {
  type        = string
  default     = ""
  sensitive   = true
  description = "Optional Telegram chat or channel ID used for the deployment notification"
}
