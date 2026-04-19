# Provider Compatibility Report: Ollama (gemma4:31b)
**Endpoint:** `https://woys3dmwutej9n-11434.proxy.runpod.net/v1`

## 🔴 Verdict: Not Suitable as Primary Provider (Experimental)
The backend is **not cleanly OpenAI-compatible**. It exhibits critical non-standard behavior regarding reasoning tokens and token counting that would break most standard OpenAI clients without a custom adapter.

### Observed Response Shape
```json
{
  "choices": [{
    "message": {
      "role": "assistant",
      "content": "...", 
      "reasoning": "..." // NON-STANDARD FIELD
    },
    "finish_reason": "stop" | "length"
  }],
  "usage": { "prompt_tokens": 0, "completion_tokens": 0 }
}
```

### Critical Compatibility Issues
1.  **Reasoning Leakage**: The model returns internal reasoning in a separate `message.reasoning` field. This is not part of the OpenAI spec.
2.  **Token Budget Theft**: The `completion_tokens` count includes **both** the reasoning and the content.
3.  **Empty Content Hazard**: When `max_tokens` is low (e.g., 64, 256), the model spends the entire budget on `reasoning`. This results in `content: ""` and `finish_reason: "length"`, even though the model hasn't started answering.
4.  **System Instruction Ignored**: The model continued to generate reasoning even when explicitly told: *"Do not include reasoning. Output only the final answer."*

### Test Matrix Summary
| Test Case | Result | `content` | `reasoning` | `finish_reason` | Notes |
| :--- | :--- | :--- | :--- | :--- | :--- |
| Minimal Prompt | PASS | "OK" | Populated | `stop` | Works, but reasoning is leaked. |
| System (No Reas.) | FAIL | "4" | Populated | `stop` | Ignored negative constraint. |
| Medium Prompt | PASS | Populated | Populated | `stop` | Standard behavior. |
| Long (No limit) | PASS | Populated | Populated | `stop` | Standard behavior. |
| Long (max=64) | **FAIL** | **Empty** | Populated | `length` | Budget exhausted by reasoning. |
| Long (max=256) | **FAIL** | **Empty** | Populated | `length` | Budget exhausted by reasoning. |
| Long (max=1024) | FAIL | Partial | Populated | `length` | Budget split between Reas/Cont. |

## Recommendations & Config

### Provider-Side Handling (Adapter Requirements)
*   **Filter Reasoning**: `opencode` must explicitly ignore `message.reasoning` to avoid leaking internal thoughts to the user.
*   **Invalid Response Logic**: Treat `content == ""` AND `reasoning != ""` as an **invalid response** or a "hidden failure," even if `finish_reason` is "length".
*   **Budget Padding**: If `max_tokens` is required, it must be significantly padded (e.g., `requested_tokens + 500`) to account for the mandatory reasoning overhead.
*   **Retry Strategy**: Trigger a retry if `finish_reason: "length"` occurs while `content` is empty.

### Suggested Config Defaults
*   **Max Tokens**: Set to `4096` or higher (avoid low limits).
*   **Streaming**: Supported and stable.
*   **Classification**: `Experimental / High-Risk`.

**Can opencode safely support it?**
Only with a **custom adapter** that strips the `reasoning` field and handles the "empty content" edge case. Out-of-the-box OpenAI clients will likely show empty responses for medium-length prompts with tight token limits.
