{ pkgs }:

pkgs.writeScriptBin "agent-chainer" ''
  #!${pkgs.python312.withPackages (ps: [ ps.requests ])}/bin/python3
  import requests
  import json
  import sys
  import time

  # Configuration
  PORT_REASONER = 8013  # GPT-OSS 120B
  PORT_CODER = 8012     # Qwen3-Coder
  MODEL_REASONER = "openai/gpt-oss"
  MODEL_CODER = "openai/qwen-coder"

  def query_llm(port, prompt, system_prompt="You are a helpful AI."):
      url = f"http://127.0.0.1:{port}/v1/chat/completions"
      headers = {"Content-Type": "application/json"}
      data = {
          "messages": [
              {"role": "system", "content": system_prompt},
              {"role": "user", "content": prompt}
          ],
          "temperature": 0.2,
      }
      
      try:
          response = requests.post(url, headers=headers, json=data, timeout=600)
          response.raise_for_status()
          return response.json()['choices'][0]['message']['content']
      except Exception as e:
          print(f"\nError querying LLM on port {port}: {e}")
          return None

  def main():
      if len(sys.argv) < 2:
          print("Usage: agent-chainer \"Your task description\"")
          sys.exit(1)

      user_task = sys.argv[1]

      print("\n[1/2] 🧠 Architect (GPT-OSS 120B) is planning...")
      start_time = time.time()
      
      architect_system = "You are a Lead Software Architect. Create a detailed technical plan for the requested task. Focus on structure, logic, and efficiency. Do not write the final code, only the specification."
      plan = query_llm(PORT_REASONER, user_task, architect_system)
      
      if not plan:
          print("Failed to get plan from Architect.")
          return

      print(f"Plan generated in {time.time() - start_time:.1f}s.")
      print("-" * 40)
      print(plan)
      print("-" * 40)

      print("\n[2/2] 💻 Coder (Qwen3-Next) is implementing...")
      start_time = time.time()
      
      coder_system = "You are an expert Python Coder. Implement the following technical plan exactly. Provide only the valid Python code, no explanation."
      code = query_llm(PORT_CODER, f"Plan: {plan}\n\nTask: {user_task}", coder_system)
      
      if not code:
          print("Failed to get code from Coder.")
          return

      print(f"Code generated in {time.time() - start_time:.1f}s.")
      print("-" * 40)
      print(code)
      print("-" * 40)

      # Extract code block if present
      clean_code = code
      if "```python" in code:
          clean_code = code.split("```python")[1].split("```")[0]
      elif "```" in code:
          clean_code = code.split("```")[1].split("```")[0]

      filename = "output.py"
      with open(filename, "w") as f:
          f.write(clean_code.strip())
      print(f"\n✅ Success! Result saved to {filename}")

  if __name__ == "__main__":
      main()
''
