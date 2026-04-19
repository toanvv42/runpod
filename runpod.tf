terraform {
  backend "s3" {
    bucket       = "terraform-state-421427265342-ap-southeast-1-runpod"
    key          = "runpod/terraform.tfstate"
    region       = "ap-southeast-1"
    encrypt      = true
    use_lockfile = true
  }

  required_providers {
    runpod = {
      source  = "decentralized-infrastructure/runpod"
      version = "~> 1.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }
}


provider "runpod" {
  api_key = var.runpod_api_key
}

resource "random_id" "pod_suffix" {
  byte_length = 4
}

locals {
  ollama_base_url = "https://${runpod_pod.gemma4_ollama.id}-11434.proxy.runpod.net"
  model           = var.ollama_model
}

resource "runpod_pod" "gemma4_ollama" {
  name              = "gemma4-ollama-${random_id.pod_suffix.hex}"
  image_name        = "ollama/ollama:latest"
  gpu_type_ids      = ["NVIDIA A100-SXM4-80GB"]
  gpu_count         = 1
  cloud_type        = "COMMUNITY"
  volume_in_gb      = 100
  support_public_ip = true
  interruptible     = var.use_spot

  ports = [
    "11434/http",
    "22/tcp"
  ]

  env = {

    OLLAMA_MODELS  = "/workspace/ollama"
    OLLAMA_NUM_CTX = "131072"
  }
}

# Wait for Ollama to be ready, then pull and smoke-test the model
resource "null_resource" "setup" {
  depends_on = [runpod_pod.gemma4_ollama]

  triggers = {
    pod_id = runpod_pod.gemma4_ollama.id
  }

  # Wait for Ollama to respond
  provisioner "local-exec" {
    command = <<-EOT
      echo "Waiting for Ollama to be ready..."
      for i in $(seq 1 60); do
        if curl -fs --max-time 5 ${local.ollama_base_url}/api/tags > /dev/null 2>&1; then
          echo "Ollama is ready!"
          break
        fi
        echo "Attempt $i/60 - waiting 5s..."
        sleep 5
      done
    EOT
  }

  # Pull the model
  provisioner "local-exec" {
    command = <<-EOT
      echo "Pulling ${local.model}..."
      curl -X POST ${local.ollama_base_url}/api/pull \
        -d "{\"name\":\"${local.model}\",\"stream\":false}" \
        --max-time 900
      echo ""
      echo "Model pull complete."
    EOT
  }

  # Smoke test the base endpoint response after the model pull completes.
  provisioner "local-exec" {
    command = <<-EOT
      echo "Smoke testing endpoint response..."
      for i in $(seq 1 30); do
        RESP=$(curl -fsS --max-time 10 ${local.ollama_base_url})
        if echo "$RESP" | grep -q "Ollama is running"; then
          echo "Smoke test passed!"
          exit 0
        fi
        echo "Attempt $i/30 - endpoint not ready, waiting 10s..."
        sleep 10
      done
      echo "Smoke test failed after retries"
      exit 1
    EOT
  }
}

# Outputs
output "pod_id" {
  value = runpod_pod.gemma4_ollama.id
}

output "ollama_endpoint" {
  description = "Ollama OpenAI-compatible API base URL"
  value       = "${local.ollama_base_url}/v1"
}
