# Ollama OpenAI Compatibility Research

## Context

This note summarizes what we found while investigating the RunPod Ollama endpoint:

- Endpoint under test: `https://woys3dmwutej9n-11434.proxy.runpod.net/v1`
- Model under test: `gemma4:31b`
- Main symptom:
  - `choices[0].message.reasoning` is populated
  - `choices[0].message.content` may be empty
  - `finish_reason` may be `"length"` when the token budget is consumed by reasoning first

This behavior breaks clients that assume normal OpenAI chat-completions semantics.

## What Upstream Says

### 1. The issue is real and not unique to this deployment

Ollama issue `#15288` describes the same Gemma 4 behavior on `/v1/chat/completions`:

- `content` empty
- output only in `reasoning`
- native `/api/chat` works with `think:false`

Source:
- <https://github.com/ollama/ollama/issues/15288>

### 2. Ollama now documents reasoning controls on `/v1/chat/completions`

Ollama's OpenAI-compat docs currently list these request fields for `/v1/chat/completions`:

- `reasoning_effort`
- `reasoning.effort`

Accepted values include:

- `"high"`
- `"medium"`
- `"low"`
- `"none"`

Relevant docs:
- <https://docs.ollama.com/api/openai-compatibility>

There is also an Ollama issue documenting this behavior and the mapping:

- `"none"` => thinking off
- `"high"`, `"medium"`, `"low"` => thinking on

Source:
- <https://github.com/ollama/ollama/issues/14820>

### 3. Native Ollama API has cleaner thinking control

Ollama native `/api/chat` supports `think` directly, including `think:false`.

Docs:
- <https://docs.ollama.com/api/chat>

This is important because Gemma 4 appears to behave better on native `/api/chat` than on the OpenAI-compatible `/v1` route.

### 4. Other people are building proxies

A recent public Ollama issue (`#15368`) describes a practical workaround:

- translate `/v1/chat/completions` requests to `/api/chat`
- send `think:false`
- convert the native response back into OpenAI-style response shape

Source:
- <https://github.com/ollama/ollama/issues/15368>

## Practical Conclusions

### The backend problem is real

This is not just an OpenClaw local bug. There is upstream evidence that Gemma 4 plus Ollama `/v1/chat/completions` can produce exactly this failure mode.

### Best serving path

Preferred order:

1. Use native Ollama `/api/chat`
2. If OpenAI compatibility is mandatory, test `reasoning_effort: "none"`
3. If `/v1` still behaves badly, place a compatibility proxy in front of Ollama

### Best client behavior

Clients should not assume this backend is strictly OpenAI-compatible. At minimum they should:

- ignore `message.reasoning` in normal output rendering
- treat empty `content` plus non-empty `reasoning` as a hidden failure
- retry or fallback when `finish_reason == "length"` and `content` is empty

## What This Means For This Repo

### Was the Terraform update still necessary?

Yes, it is still useful.

The Terraform changes did not try to fix the upstream Ollama `/v1` behavior directly. They did three practical things:

1. Exposed both endpoints separately
   - native Ollama API
   - OpenAI-compatible API marked experimental
2. Stopped the repo from implicitly presenting `/v1` as the default or only endpoint
3. Added `ollama_image_name` so we can later pin a specific Ollama version or swap in a custom wrapper image

That is still the right repo-level move because:

- the native endpoint is currently the safer path
- the OpenAI-compatible path should be clearly labeled experimental
- we may want to replace `ollama/ollama:latest` with a pinned version or custom proxy image later

### What Terraform alone cannot fix

Terraform cannot change how Ollama's `/v1` implementation serializes reasoning unless we deploy a different image or add a wrapper/proxy.

So the repo can help with:

- safer defaults
- clearer outputs
- image override/pinning

But the repo cannot fully solve:

- `reasoning` leakage from Ollama `/v1`
- empty `content` responses
- broken thinking behavior for Gemma 4 on `/v1`

## Recommended Next Steps

1. Test `/v1/chat/completions` with `reasoning_effort: "none"`
2. If still broken, prefer native `/api/chat` for Gemma 4
3. If OpenClaw must consume OpenAI-style APIs, build a small proxy that:
   - accepts OpenAI chat requests
   - forwards to `/api/chat`
   - forces `think:false`
   - returns OpenAI-style responses
4. Consider pinning the Ollama image instead of using `ollama/ollama:latest`

## Links

- Ollama issue `#15288`: <https://github.com/ollama/ollama/issues/15288>
- Ollama issue `#14820`: <https://github.com/ollama/ollama/issues/14820>
- Ollama issue `#15368`: <https://github.com/ollama/ollama/issues/15368>
- Ollama OpenAI compatibility docs: <https://docs.ollama.com/api/openai-compatibility>
- Ollama native chat docs: <https://docs.ollama.com/api/chat>
- Open WebUI reasoning docs: <https://docs.openwebui.com/features/chat-features/reasoning-models/>
