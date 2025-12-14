./llama.cpp/build/bin/llama-server \
  -m /root/models/Qwen3-0.6B-Q8_0.gguf \
  --jinja \
  -t 4 \
  --mlock \
  -c 4096 \
  --host 0.0.0.0 \
  --chat-template-file /root/llama.cpp/models/templates/qwen3_nonthinking.jinja \
  --no_warmup \
