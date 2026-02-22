import flask
import requests
import json

app = flask.Flask(__name__)

# Mapping of model identifiers to their respective backend ports
MODEL_MAPPING = {
    "openai/gpt-oss": 8013,
    "openai/qwen-coder": 8012
}

@app.route('/v1/chat/completions', methods=['POST'])
@app.route('/chat/completions', methods=['POST'])
def chat_proxy():
    data = flask.request.get_json()
    model = data.get('model', 'openai/qwen-coder')
    
    # Route based on model name
    port = MODEL_MAPPING.get(model, 8012)
    url = f"http://127.0.0.1:{port}/v1/chat/completions"
    
    print(f"Routing request for {model} to port {port}")
    
    try:
        resp = requests.post(url, json=data, stream=data.get('stream', False))
        
        if data.get('stream', False):
            def generate():
                for chunk in resp.iter_content(chunk_size=1024):
                    yield chunk
            return flask.Response(generate(), content_type=resp.headers.get('Content-Type'))
        else:
            return flask.Response(resp.content, status=resp.status_code, content_type=resp.headers.get('Content-Type'))
    except Exception as e:
        return flask.jsonify({"error": str(e)}), 500

@app.route('/v1/models', methods=['GET'])
@app.route('/models', methods=['GET'])
def models_proxy():
    return flask.jsonify({
        "object": "list",
        "data": [
            {"id": "openai/gpt-oss", "object": "model", "owned_by": "local"},
            {"id": "openai/qwen-coder", "object": "model", "owned_by": "local"}
        ]
    })

if __name__ == '__main__':
    print("Starting dual-model proxy on port 8000...")
    app.run(host='0.0.0.0', port=8000)
