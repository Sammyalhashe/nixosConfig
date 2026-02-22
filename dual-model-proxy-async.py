import aiohttp
from aiohttp import web
import json
import logging

# Configure logging
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(message)s')
logger = logging.getLogger(__name__)

# Mapping of model identifiers to their respective backend ports
MODEL_MAPPING = {
    "openai/gpt-oss": 8013,
    "openai/qwen-coder": 8012
}

async def handle_chat_completions(request):
    try:
        data = await request.json()
    except json.JSONDecodeError:
        return web.Response(text="Invalid JSON", status=400)

    model = data.get('model', 'openai/qwen-coder')
    
    # Route based on model name
    port = MODEL_MAPPING.get(model, 8012)
    url = f"http://127.0.0.1:{port}/v1/chat/completions"
    
    logger.info(f"Routing request for {model} to port {port}")
    
    # Prepare headers (copy relevant ones)
    headers = {k: v for k, v in request.headers.items() if k.lower() in ['content-type', 'authorization']}
    
    async with aiohttp.ClientSession() as session:
        try:
            # Determine timeout based on model (give GPT-OSS more time)
            timeout_seconds = 600 if port == 8013 else 300
            timeout = aiohttp.ClientTimeout(total=timeout_seconds)
            
            async with session.post(url, json=data, headers=headers, timeout=timeout) as resp:
                logger.info(f"Backend response status: {resp.status}")
                
                if resp.status != 200:
                    error_text = await resp.text()
                    logger.error(f"Backend error: {error_text}")
                    return web.Response(text=error_text, status=resp.status, content_type='application/json')

                # Handle streaming response
                if data.get('stream', False):
                    response = web.StreamResponse(
                        status=200,
                        reason='OK',
                        headers={'Content-Type': 'text/event-stream'}
                    )
                    await response.prepare(request)
                    
                    async for chunk in resp.content.iter_any():
                        await response.write(chunk)
                    
                    await response.write_eof()
                    return response
                else:
                    # Handle normal response
                    response_json = await resp.json()
                    return web.json_response(response_json)
                    
        except Exception as e:
            logger.error(f"Error forwarding request: {str(e)}")
            return web.Response(text=json.dumps({"error": str(e)}), status=500, content_type='application/json')

async def handle_models(request):
    return web.json_response({
        "object": "list",
        "data": [
            {"id": "openai/gpt-oss", "object": "model", "owned_by": "local"},
            {"id": "openai/qwen-coder", "object": "model", "owned_by": "local"}
        ]
    })

app = web.Application()
app.router.add_post('/v1/chat/completions', handle_chat_completions)
app.router.add_post('/chat/completions', handle_chat_completions)
app.router.add_get('/v1/models', handle_models)
app.router.add_get('/models', handle_models)

if __name__ == '__main__':
    logger.info("Starting async dual-model proxy on port 8000...")
    web.run_app(app, host='0.0.0.0', port=8000)
