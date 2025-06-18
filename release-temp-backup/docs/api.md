# 🔌 llama-chat API Documentation

Complete REST API reference for llama-chat with llama.cpp integration, including examples and performance metrics.

## 📋 Table of Contents

- [Overview](#overview)
- [Base URL](#base-url)
- [Authentication](#authentication)
- [Response Format](#response-format)
- [Error Handling](#error-handling)
- [API Endpoints](#api-endpoints)
  - [Models](#models)
  - [Configuration](#configuration)
  - [Conversations](#conversations)
  - [Messages](#messages)
  - [Statistics](#statistics)
  - [Search](#search)
- [Performance Metrics](#performance-metrics)
- [SDK Examples](#sdk-examples)
- [Integration Examples](#integration-examples)

---

## Overview

The llama-chat API provides RESTful endpoints for managing conversations, sending messages to llama.cpp models, and configuring the chat interface. All endpoints return JSON responses and support standard HTTP methods.

### API Features
- 🔗 **RESTful Design** - Standard HTTP methods and status codes
- 📝 **JSON Format** - All requests and responses use JSON
- 🔍 **Full-text Search** - Search conversations and messages
- ⚙️ **Configuration Management** - Runtime configuration access
- 💬 **Real-time Chat** - Direct llama.cpp integration
- 📊 **Model Management** - Dynamic model selection and info
- ⚡ **Performance Metrics** - Response times and token tracking
- 📈 **Analytics** - Conversation statistics and insights

---

## Base URL

```
http://localhost:3000/api
```

**Production/Remote:**
```
http://your-server:port/api
```

---

## Authentication

Currently, llama-chat operates without authentication (local use). For production deployments, consider adding:
- API keys via llama.cpp server
- JWT tokens
- Basic authentication
- OAuth integration

---

## Response Format

### Success Response
```json
{
  "success": true,
  "data": { ... },
  "message": "Optional success message"
}
```

### Error Response
```json
{
  "success": false,
  "error": "Error description",
  "code": "ERROR_CODE",
  "details": { ... }
}
```

### HTTP Status Codes
- `200` - Success
- `201` - Created
- `400` - Bad Request
- `404` - Not Found
- `500` - Internal Server Error

---

## Error Handling

### Common Error Types

#### Validation Error (400)
```json
{
  "error": "Missing required field: message",
  "code": "VALIDATION_ERROR",
  "field": "message"
}
```

#### Not Found Error (404)
```json
{
  "error": "Conversation not found",
  "code": "NOT_FOUND",
  "resource": "conversation",
  "id": 123
}
```

#### Server Error (500)
```json
{
  "error": "llama.cpp server unavailable",
  "code": "LLAMACPP_ERROR",
  "details": "Connection timeout"
}
```

---

# API Endpoints

## Models

### GET /api/models
Get list of available llama.cpp models.

#### Request
```http
GET /api/models HTTP/1.1
Host: localhost:3000
Content-Type: application/json
```

#### Response
```json
{
  "models": [
    "qwen2.5-0.5b-instruct-q4_0.gguf",
    "phi3-mini-4k-instruct-q4.gguf",
    "tinyllama-1.1b-chat-v1.0.Q4_0.gguf"
  ],
  "count": 3,
  "llamacpp_url": "http://localhost:8080"
}
```

#### Error Response
```json
{
  "models": [],
  "count": 0,
  "error": "Connection to llama.cpp failed",
  "llamacpp_url": "http://localhost:8080"
}
```

#### cURL Example
```bash
curl -X GET http://localhost:3000/api/models
```

#### JavaScript Example
```javascript
const response = await fetch('/api/models');
const data = await response.json();
console.log('Available models:', data.models);
```

---

## Configuration

### GET /api/config
Get current application configuration (excluding sensitive data).

#### Request
```http
GET /api/config HTTP/1.1
Host: localhost:3000
```

#### Response
```json
{
  "timeouts": {
    "llamacpp_timeout": 600,
    "llamacpp_connect_timeout": 45
  },
  "model_options": {
    "temperature": 0.1,
    "top_p": 0.95,
    "top_k": 50,
    "min_p": 0.01,
    "num_predict": 4096,
    "repeat_penalty": 1.15,
    "stop": ["\n\nHuman:", "\n\nUser:"]
  },
  "performance": {
    "context_history_limit": 15,
    "num_thread": -1,
    "use_mlock": true,
    "use_mmap": true
  },
  "response_optimization": {
    "stream": false,
    "keep_alive": "10m"
  }
}
```

#### cURL Example
```bash
curl -X GET http://localhost:3000/api/config
```

#### Python Example
```python
import requests

response = requests.get('http://localhost:3000/api/config')
config = response.json()
print(f"Timeout: {config['timeouts']['llamacpp_timeout']}s")
```

---

## Conversations

### GET /api/conversations
Get list of all conversations ordered by last update.

#### Request
```http
GET /api/conversations HTTP/1.1
Host: localhost:3000
```

#### Query Parameters
| Parameter | Type | Description |
|-----------|------|-------------|
| `limit` | integer | Number of conversations to return (default: all) |
| `offset` | integer | Number of conversations to skip |

#### Response
```json
{
  "conversations": [
    {
      "id": 1,
      "title": "Python Development Help",
      "model": "qwen2.5-0.5b-instruct-q4_0.gguf",
      "created_at": "2025-06-08T10:30:00Z",
      "updated_at": "2025-06-08T11:45:30Z"
    },
    {
      "id": 2,
      "title": "Recipe Ideas",
      "model": "phi3-mini-4k-instruct-q4.gguf",
      "created_at": "2025-06-08T09:15:00Z",
      "updated_at": "2025-06-08T09:45:00Z"
    }
  ]
}
```

#### cURL Example
```bash
curl -X GET http://localhost:3000/api/conversations
```

### POST /api/conversations
Create a new conversation.

#### Request
```http
POST /api/conversations HTTP/1.1
Host: localhost:3000
Content-Type: application/json

{
  "title": "New Project Discussion",
  "model": "qwen2.5-0.5b-instruct-q4_0.gguf"
}
```

#### Request Body
| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `title` | string | Yes | Conversation title |
| `model` | string | Yes | llama.cpp model to use |

#### Response
```json
{
  "conversation_id": 3
}
```

#### cURL Example
```bash
curl -X POST http://localhost:3000/api/conversations \
  -H "Content-Type: application/json" \
  -d '{
    "title": "New Project Discussion",
    "model": "qwen2.5-0.5b-instruct-q4_0.gguf"
  }'
```

### GET /api/conversations/{id}
Get specific conversation with all messages and statistics.

#### Request
```http
GET /api/conversations/1 HTTP/1.1
Host: localhost:3000
```

#### Response
```json
{
  "conversation": {
    "id": 1,
    "title": "Python Development Help",
    "model": "qwen2.5-0.5b-instruct-q4_0.gguf",
    "created_at": "2025-06-08T10:30:00Z",
    "updated_at": "2025-06-08T11:45:30Z"
  },
  "messages": [
    {
      "id": 1,
      "conversation_id": 1,
      "role": "user",
      "content": "How do I create a virtual environment in Python?",
      "model": null,
      "timestamp": "2025-06-08T10:30:15Z",
      "response_time_ms": null,
      "estimated_tokens": 12
    },
    {
      "id": 2,
      "conversation_id": 1,
      "role": "assistant",
      "content": "To create a virtual environment in Python, you can use...",
      "model": "qwen2.5-0.5b-instruct-q4_0.gguf",
      "timestamp": "2025-06-08T10:30:45Z",
      "response_time_ms": 1250,
      "estimated_tokens": 89
    }
  ],
  "stats": {
    "total_messages": 12,
    "assistant_messages": 6,
    "avg_response_time": 1456.7,
    "total_tokens": 1580
  }
}
```

#### Enhanced Fields:
- **`response_time_ms`** - Response time in milliseconds (assistant messages only)
- **`estimated_tokens`** - Estimated token count for all messages
- **`stats`** - Conversation statistics object

### PUT /api/conversations/{id}
Update conversation (rename).

#### Request
```http
PUT /api/conversations/1 HTTP/1.1
Host: localhost:3000
Content-Type: application/json

{
  "title": "Updated Conversation Title"
}
```

#### Response
```json
{
  "success": true,
  "title": "Updated Conversation Title"
}
```

### DELETE /api/conversations/{id}
Delete conversation and all its messages.

#### Request
```http
DELETE /api/conversations/1 HTTP/1.1
Host: localhost:3000
```

#### Response
```json
{
  "success": true
}
```

---

## Messages

### POST /api/chat
Send a message and get AI response with performance metrics.

#### Request
```http
POST /api/chat HTTP/1.1
Host: localhost:3000
Content-Type: application/json

{
  "conversation_id": 1,
  "message": "Explain machine learning in simple terms",
  "model": "qwen2.5-0.5b-instruct-q4_0.gguf"
}
```

#### Request Body
| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `conversation_id` | integer | Yes | Target conversation ID |
| `message` | string | Yes | User message content |
| `model` | string | Yes | llama.cpp model to use |

#### Response
```json
{
  "response": "Machine learning is a type of artificial intelligence where computers learn patterns from data to make predictions or decisions without being explicitly programmed for each task...",
  "model": "qwen2.5-0.5b-instruct-q4_0.gguf",
  "response_time_ms": 1250,
  "estimated_tokens": 247,
  "metrics": {
    "completion_tokens": 247,
    "prompt_tokens": 89,
    "total_tokens": 336
  }
}
```

#### Enhanced Response Fields:
- **`response_time_ms`** - Total response time in milliseconds
- **`estimated_tokens`** - Estimated token count for the response
- **`metrics`** - Detailed performance metrics from llama.cpp

#### Performance Calculation Examples:
```javascript
// Tokens per second calculation
const tokensPerSecond = data.estimated_tokens / (data.response_time_ms / 1000);

// Display performance
console.log(`Speed: ${tokensPerSecond.toFixed(1)} tokens/sec`);
```

#### cURL Example
```bash
curl -X POST http://localhost:3000/api/chat \
  -H "Content-Type: application/json" \
  -d '{
    "conversation_id": 1,
    "message": "Explain machine learning in simple terms",
    "model": "qwen2.5-0.5b-instruct-q4_0.gguf"
  }'
```

#### Python Example
```python
import requests

response = requests.post('http://localhost:3000/api/chat', json={
    'conversation_id': 1,
    'message': 'Explain machine learning in simple terms',
    'model': 'qwen2.5-0.5b-instruct-q4_0.gguf'
})

data = response.json()
print(f"AI Response: {data['response']}")
print(f"Response Time: {data['response_time_ms']}ms")
print(f"Tokens: ~{data['estimated_tokens']}")
print(f"Speed: {data['estimated_tokens'] / (data['response_time_ms'] / 1000):.1f} tokens/sec")
```

---

## Statistics

### GET /api/stats/{conversation_id}
Get detailed conversation statistics and analytics.

#### Request
```http
GET /api/stats/1 HTTP/1.1
Host: localhost:3000
```

#### Response
```json
{
  "summary": {
    "total_messages": 24,
    "assistant_messages": 12,
    "avg_response_time": 1456.7,
    "total_tokens": 3240
  },
  "by_role": [
    {
      "role": "user",
      "count": 12,
      "avg_length": 45.3,
      "total_tokens": 156,
      "avg_response_time": null
    },
    {
      "role": "assistant",
      "count": 12,
      "avg_length": 287.5,
      "total_tokens": 3084,
      "avg_response_time": 1456.7
    }
  ]
}
```

#### cURL Example
```bash
curl -X GET http://localhost:3000/api/stats/1
```

#### Use Cases:
- **Performance monitoring** - Track AI response times
- **Usage analytics** - Monitor token consumption
- **Conversation insights** - Understand chat patterns
- **Optimization** - Identify performance bottlenecks

---

## Search

### GET /api/search
Search conversations and messages with performance metrics.

#### Request
```http
GET /api/search?q=machine%20learning HTTP/1.1
Host: localhost:3000
```

#### Query Parameters
| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `q` | string | Yes | Search query |
| `limit` | integer | No | Max results (default: 50) |

#### Response
```json
{
  "results": [
    {
      "id": 1,
      "title": "AI Development Discussion",
      "model": "qwen2.5-0.5b-instruct-q4_0.gguf",
      "updated_at": "2025-06-08T11:45:30Z",
      "content": "Machine learning is a subset of artificial intelligence...",
      "role": "assistant",
      "timestamp": "2025-06-08T11:30:00Z",
      "response_time_ms": 1250,
      "estimated_tokens": 156
    }
  ],
  "query": "machine learning",
  "count": 1
}
```

#### cURL Example
```bash
curl -X GET "http://localhost:3000/api/search?q=machine%20learning"
```

---

## Performance Metrics

### llama.cpp Integration

llama-chat integrates directly with llama.cpp server to provide detailed performance metrics:

#### Token Metrics
- **Prompt tokens** - Input processing
- **Completion tokens** - Generated response
- **Total tokens** - Combined usage
- **Tokens per second** - Generation speed

#### Timing Metrics
- **Response time** - End-to-end request time
- **Processing time** - Model inference time
- **Network latency** - Communication overhead

#### Example Performance Response
```json
{
  "response": "Generated text here...",
  "response_time_ms": 1250,
  "estimated_tokens": 247,
  "metrics": {
    "completion_tokens": 247,
    "prompt_tokens": 89,
    "total_tokens": 336,
    "tokens_per_second": 12.5
  }
}
```

---

## SDK Examples

### Python SDK Example

```python
import requests
from typing import List, Dict, Optional

class LlamaChatAPI:
    def __init__(self, base_url: str = "http://localhost:3000"):
        self.base_url = base_url
        self.api_url = f"{base_url}/api"

    def get_models(self) -> List[str]:
        """Get available llama.cpp models."""
        response = requests.get(f"{self.api_url}/models")
        response.raise_for_status()
        return response.json()["models"]

    def create_conversation(self, title: str, model: str) -> int:
        """Create a new conversation."""
        response = requests.post(f"{self.api_url}/conversations", json={
            "title": title,
            "model": model
        })
        response.raise_for_status()
        return response.json()["conversation_id"]

    def send_message(self, conversation_id: int, message: str, model: str) -> Dict:
        """Send a message and get AI response with metrics."""
        response = requests.post(f"{self.api_url}/chat", json={
            "conversation_id": conversation_id,
            "message": message,
            "model": model
        })
        response.raise_for_status()
        return response.json()

    def get_conversation_stats(self, conversation_id: int) -> Dict:
        """Get detailed conversation statistics."""
        response = requests.get(f"{self.api_url}/stats/{conversation_id}")
        response.raise_for_status()
        return response.json()

    def search(self, query: str, limit: int = 50) -> List[Dict]:
        """Search conversations and messages."""
        response = requests.get(f"{self.api_url}/search", params={
            "q": query,
            "limit": limit
        })
        response.raise_for_status()
        return response.json()["results"]

# Usage example with performance tracking
api = LlamaChatAPI()

# Get available models
models = api.get_models()
print(f"Available models: {models}")

# Create a conversation
conv_id = api.create_conversation("Python Help", models[0])
print(f"Created conversation: {conv_id}")

# Send a message and track performance
result = api.send_message(conv_id, "What is Python?", models[0])
print(f"AI Response: {result['response']}")
print(f"Performance: {result['response_time_ms']}ms, ~{result['estimated_tokens']} tokens")
if result['response_time_ms'] > 0:
    tokens_per_sec = result['estimated_tokens'] / (result['response_time_ms'] / 1000)
    print(f"Speed: {tokens_per_sec:.1f} tokens/sec")

# Get conversation statistics
stats = api.get_conversation_stats(conv_id)
print(f"Conversation stats: {stats['summary']}")
```

### Node.js SDK Example

```javascript
class LlamaChatAPI {
    constructor(baseUrl = 'http://localhost:3000') {
        this.baseUrl = baseUrl;
        this.apiUrl = `${baseUrl}/api`;
    }

    async getModels() {
        const response = await fetch(`${this.apiUrl}/models`);
        const data = await response.json();
        return data.models;
    }

    async createConversation(title, model) {
        const response = await fetch(`${this.apiUrl}/conversations`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ title, model })
        });
        const data = await response.json();
        return data.conversation_id;
    }

    async sendMessage(conversationId, message, model) {
        const response = await fetch(`${this.apiUrl}/chat`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({
                conversation_id: conversationId,
                message,
                model
            })
        });
        const data = await response.json();
        return data;
    }

    async getConversationStats(conversationId) {
        const response = await fetch(`${this.apiUrl}/stats/${conversationId}`);
        const data = await response.json();
        return data;
    }

    async search(query, limit = 50) {
        const response = await fetch(`${this.apiUrl}/search?q=${encodeURIComponent(query)}&limit=${limit}`);
        const data = await response.json();
        return data.results;
    }
}

// Usage example with performance monitoring
const api = new LlamaChatAPI();

(async () => {
    try {
        // Get available models
        const models = await api.getModels();
        console.log('Available models:', models);

        // Create a conversation
        const convId = await api.createConversation('JavaScript Help', models[0]);
        console.log('Created conversation:', convId);

        // Send a message and monitor performance
        const result = await api.sendMessage(convId, 'Explain async/await', models[0]);
        console.log('AI Response:', result.response);
        console.log(`Performance: ${result.response_time_ms}ms, ~${result.estimated_tokens} tokens`);
        
        if (result.response_time_ms > 0) {
            const tokensPerSec = result.estimated_tokens / (result.response_time_ms / 1000);
            console.log(`Speed: ${tokensPerSec.toFixed(1)} tokens/sec`);
        }

        // Get conversation statistics
        const stats = await api.getConversationStats(convId);
        console.log('Conversation stats:', stats.summary);

    } catch (error) {
        console.error('API Error:', error);
    }
})();
```

---

## Integration Examples

### Performance Monitoring Dashboard

```html
<!DOCTYPE html>
<html>
<head>
    <title>llama-chat Performance Dashboard</title>
    <script src="https://cdn.jsdelivr.net/npm/chart.js"></script>
</head>
<body>
    <h1>llama-chat Performance Dashboard</h1>
    
    <div id="metrics-cards"></div>
    
    <canvas id="responseTimeChart" width="400" height="200"></canvas>
    <canvas id="tokenUsageChart" width="400" height="200"></canvas>

    <script>
        async function loadMetrics() {
            try {
                // Get all conversations
                const conversationsResponse = await fetch('/api/conversations');
                const conversations = await conversationsResponse.json();
                
                let totalMessages = 0;
                let totalTokens = 0;
                let totalResponseTime = 0;
                let responseCount = 0;
                
                const responseTimeData = [];
                const tokenUsageData = [];
                
                // Collect stats from each conversation
                for (const conv of conversations.conversations) {
                    const statsResponse = await fetch(`/api/stats/${conv.id}`);
                    if (statsResponse.ok) {
                        const stats = await statsResponse.json();
                        
                        totalMessages += stats.summary.total_messages;
                        totalTokens += stats.summary.total_tokens || 0;
                        
                        if (stats.summary.avg_response_time) {
                            totalResponseTime += stats.summary.avg_response_time;
                            responseCount++;
                            
                            responseTimeData.push({
                                conversation: conv.title,
                                responseTime: stats.summary.avg_response_time
                            });
                        }
                        
                        if (stats.summary.total_tokens) {
                            tokenUsageData.push({
                                conversation: conv.title,
                                tokens: stats.summary.total_tokens
                            });
                        }
                    }
                }
                
                // Display metric cards
                const avgResponseTime = responseCount > 0 ? (totalResponseTime / responseCount) : 0;
                const avgTokensPerSec = avgResponseTime > 0 ? (totalTokens / (avgResponseTime / 1000 * responseCount)) : 0;
                
                const metricsHtml = `
                    <div style="display: flex; gap: 20px; margin: 20px 0;">
                        <div style="border: 1px solid #ddd; padding: 20px; border-radius: 8px;">
                            <h3>${totalMessages}</h3>
                            <p>Total Messages</p>
                        </div>
                        <div style="border: 1px solid #ddd; padding: 20px; border-radius: 8px;">
                            <h3>${totalTokens.toLocaleString()}</h3>
                            <p>Total Tokens</p>
                        </div>
                        <div style="border: 1px solid #ddd; padding: 20px; border-radius: 8px;">
                            <h3>${avgResponseTime.toFixed(0)}ms</h3>
                            <p>Avg Response Time</p>
                        </div>
                        <div style="border: 1px solid #ddd; padding: 20px; border-radius: 8px;">
                            <h3>${avgTokensPerSec.toFixed(1)}</h3>
                            <p>Avg Tokens/Sec</p>
                        </div>
                    </div>
                `;
                
                document.getElementById('metrics-cards').innerHTML = metricsHtml;
                
                // Create response time chart
                if (responseTimeData.length > 0) {
                    new Chart(document.getElementById('responseTimeChart'), {
                        type: 'bar',
                        data: {
                            labels: responseTimeData.map(d => d.conversation.substring(0, 20) + '...'),
                            datasets: [{
                                label: 'Average Response Time (ms)',
                                data: responseTimeData.map(d => d.responseTime),
                                backgroundColor: 'rgba(54, 162, 235, 0.6)',
                                borderColor: 'rgba(54, 162, 235, 1)',
                                borderWidth: 1
                            }]
                        },
                        options: {
                            responsive: true,
                            plugins: {
                                title: {
                                    display: true,
                                    text: 'Response Time by Conversation'
                                }
                            }
                        }
                    });
                }
                
                // Create token usage chart
                if (tokenUsageData.length > 0) {
                    new Chart(document.getElementById('tokenUsageChart'), {
                        type: 'doughnut',
                        data: {
                            labels: tokenUsageData.map(d => d.conversation.substring(0, 20) + '...'),
                            datasets: [{
                                label: 'Token Usage',
                                data: tokenUsageData.map(d => d.tokens),
                                backgroundColor: [
                                    'rgba(255, 99, 132, 0.6)',
                                    'rgba(54, 162, 235, 0.6)',
                                    'rgba(255, 205, 86, 0.6)',
                                    'rgba(75, 192, 192, 0.6)',
                                    'rgba(153, 102, 255, 0.6)',
                                ]
                            }]
                        },
                        options: {
                            responsive: true,
                            plugins: {
                                title: {
                                    display: true,
                                    text: 'Token Usage by Conversation'
                                }
                            }
                        }
                    });
                }
                
            } catch (error) {
                console.error('Error loading metrics:', error);
            }
        }
        
        // Load metrics on page load
        loadMetrics();
        
        // Refresh every 30 seconds
        setInterval(loadMetrics, 30000);
    </script>
</body>
</html>
```

### Batch Processing Example

```python
import asyncio
import aiohttp
import time
from concurrent.futures import ThreadPoolExecutor

class LlamaChatBatchProcessor:
    def __init__(self, base_url="http://localhost:3000"):
        self.base_url = base_url
        self.api_url = f"{base_url}/api"

    async def process_batch(self, conversation_id: int, messages: list, model: str):
        """Process multiple messages concurrently."""
        async with aiohttp.ClientSession() as session:
            tasks = []
            for message in messages:
                task = self.send_message_async(session, conversation_id, message, model)
                tasks.append(task)
            
            results = await asyncio.gather(*tasks, return_exceptions=True)
            return results

    async def send_message_async(self, session, conversation_id: int, message: str, model: str):
        """Send a single message asynchronously."""
        start_time = time.time()
        
        try:
            async with session.post(f"{self.api_url}/chat", json={
                "conversation_id": conversation_id,
                "message": message,
                "model": model
            }) as response:
                data = await response.json()
                
                # Add processing time
                data['client_processing_time'] = (time.time() - start_time) * 1000
                
                return data
                
        except Exception as e:
            return {"error": str(e), "message": message}

# Usage example
async def main():
    processor = LlamaChatBatchProcessor()
    
    # Create conversation first (synchronous)
    import requests
    conv_response = requests.post(f"{processor.api_url}/conversations", json={
        "title": "Batch Processing Test",
        "model": "qwen2.5-0.5b-instruct-q4_0.gguf"
    })
    conv_id = conv_response.json()["conversation_id"]
    
    # Batch process messages
    messages = [
        "What is Python?",
        "Explain machine learning",
        "How does HTTP work?",
        "What is a database?",
        "Explain REST APIs"
    ]
    
    print("Processing batch of messages...")
    start_time = time.time()
    
    results = await processor.process_batch(conv_id, messages, "qwen2.5-0.5b-instruct-q4_0.gguf")
    
    total_time = time.time() - start_time
    
    # Analyze results
    successful_responses = [r for r in results if 'error' not in r]
    total_tokens = sum(r.get('estimated_tokens', 0) for r in successful_responses)
    avg_response_time = sum(r.get('response_time_ms', 0) for r in successful_responses) / len(successful_responses)
    
    print(f"\nBatch Processing Results:")
    print(f"Total processing time: {total_time:.2f}s")
    print(f"Successful responses: {len(successful_responses)}/{len(messages)}")
    print(f"Total tokens generated: {total_tokens}")
    print(f"Average response time: {avg_response_time:.1f}ms")
    print(f"Overall tokens/sec: {total_tokens / total_time:.1f}")

# Run the async batch processor
if __name__ == "__main__":
    asyncio.run(main())
```

### Real-time Streaming Example

```javascript
// WebSocket-like streaming simulation using polling
class LlamaChatStreamer {
    constructor(baseUrl = 'http://localhost:3000') {
        this.baseUrl = baseUrl;
        this.apiUrl = `${baseUrl}/api`;
    }

    async streamResponse(conversationId, message, model, onToken, onComplete) {
        try {
            // Send message
            const response = await fetch(`${this.apiUrl}/chat`, {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({
                    conversation_id: conversationId,
                    message: message,
                    model: model
                })
            });

            const data = await response.json();
            
            // Simulate streaming by breaking response into chunks
            const fullResponse = data.response;
            const words = fullResponse.split(' ');
            let currentText = '';
            
            for (let i = 0; i < words.length; i++) {
                currentText += (i > 0 ? ' ' : '') + words[i];
                
                // Call token callback
                onToken({
                    text: currentText,
                    isComplete: i === words.length - 1,
                    progress: (i + 1) / words.length
                });
                
                // Small delay to simulate streaming
                await new Promise(resolve => setTimeout(resolve, 50));
            }
            
            // Call completion callback
            onComplete({
                fullResponse: data.response,
                responseTime: data.response_time_ms,
                tokens: data.estimated_tokens,
                metrics: data.metrics
            });
            
        } catch (error) {
            console.error('Streaming error:', error);
            onComplete({ error: error.message });
        }
    }
}

// Usage example
const streamer = new LlamaChatStreamer();

streamer.streamResponse(
    1, // conversation ID
    "Explain quantum computing",
    "qwen2.5-0.5b-instruct-q4_0.gguf",
    
    // Token callback - called for each token
    (data) => {
        document.getElementById('response-text').textContent = data.text;
        
        // Update progress bar
        const progressBar = document.getElementById('progress-bar');
        progressBar.style.width = `${data.progress * 100}%`;
    },
    
    // Completion callback
    (data) => {
        if (data.error) {
            console.error('Stream error:', data.error);
            return;
        }
        
        console.log('Stream complete!');
        console.log(`Response time: ${data.responseTime}ms`);
        console.log(`Tokens: ${data.tokens}`);
        console.log(`Speed: ${(data.tokens / (data.responseTime / 1000)).toFixed(1)} tok/s`);
        
        // Hide progress bar
        document.getElementById('progress-bar').style.display = 'none';
    }
);
```

---

## Testing and Development

### API Testing Script

```bash
#!/bin/bash
# test-llama-chat-api.sh - Comprehensive API testing

BASE_URL="http://localhost:3000/api"

echo "Testing llama-chat API..."

# Test models endpoint
echo "1. Testing /api/models"
MODELS_RESPONSE=$(curl -s "$BASE_URL/models")
echo "$MODELS_RESPONSE" | jq .

# Extract first model for testing
MODEL=$(echo "$MODELS_RESPONSE" | jq -r '.models[0]')
echo "Using model: $MODEL"

# Test config endpoint
echo -e "\n2. Testing /api/config"
curl -s "$BASE_URL/config" | jq .

# Create a test conversation
echo -e "\n3. Creating test conversation"
CONV_RESPONSE=$(curl -s -X POST "$BASE_URL/conversations" \
  -H "Content-Type: application/json" \
  -d "{\"title\": \"API Test\", \"model\": \"$MODEL\"}")

CONV_ID=$(echo "$CONV_RESPONSE" | jq -r .conversation_id)
echo "Created conversation ID: $CONV_ID"

# Send test messages and measure performance
echo -e "\n4. Sending test messages with performance tracking"

for i in {1..3}; do
    echo "Sending message $i..."
    
    CHAT_RESPONSE=$(curl -s -X POST "$BASE_URL/chat" \
      -H "Content-Type: application/json" \
      -d "{\"conversation_id\": $CONV_ID, \"message\": \"Test message $i\", \"model\": \"$MODEL\"}")
    
    echo "$CHAT_RESPONSE" | jq '{
        response_length: (.response | length),
        response_time_ms: .response_time_ms,
        estimated_tokens: .estimated_tokens,
        tokens_per_second: (.estimated_tokens / (.response_time_ms / 1000))
    }'
done

# Test conversation stats
echo -e "\n5. Testing conversation statistics"
curl -s "$BASE_URL/stats/$CONV_ID" | jq .

# Test search functionality
echo -e "\n6. Testing search"
curl -s "$BASE_URL/search?q=test" | jq '.results | length'

echo -e "\nAPI testing complete!"
```

### Performance Benchmarking

```python
#!/usr/bin/env python3
"""
Performance benchmarking script for llama-chat API
"""

import requests
import time
import statistics
import json
from concurrent.futures import ThreadPoolExecutor, as_completed

class LlamaChatBenchmark:
    def __init__(self, base_url="http://localhost:3000"):
        self.base_url = base_url
        self.api_url = f"{base_url}/api"

    def benchmark_single_requests(self, num_requests=10):
        """Benchmark sequential requests."""
        print(f"Benchmarking {num_requests} sequential requests...")
        
        # Create test conversation
        conv_response = requests.post(f"{self.api_url}/conversations", json={
            "title": "Benchmark Test",
            "model": self.get_first_model()
        })
        conv_id = conv_response.json()["conversation_id"]
        
        response_times = []
        tokens_generated = []
        tokens_per_second = []
        
        for i in range(num_requests):
            start_time = time.time()
            
            response = requests.post(f"{self.api_url}/chat", json={
                "conversation_id": conv_id,
                "message": f"Generate a {50 + i*10} word explanation of artificial intelligence.",
                "model": self.get_first_model()
            })
            
            if response.status_code == 200:
                data = response.json()
                response_times.append(data.get('response_time_ms', 0))
                tokens_generated.append(data.get('estimated_tokens', 0))
                
                if data.get('response_time_ms', 0) > 0:
                    tps = data.get('estimated_tokens', 0) / (data.get('response_time_ms', 1) / 1000)
                    tokens_per_second.append(tps)
        
        return {
            'response_times': response_times,
            'tokens_generated': tokens_generated,
            'tokens_per_second': tokens_per_second
        }

    def benchmark_concurrent_requests(self, num_concurrent=5, requests_per_worker=3):
        """Benchmark concurrent requests."""
        print(f"Benchmarking {num_concurrent} concurrent workers, {requests_per_worker} requests each...")
        
        def worker(worker_id):
            # Create conversation for this worker
            conv_response = requests.post(f"{self.api_url}/conversations", json={
                "title": f"Concurrent Test {worker_id}",
                "model": self.get_first_model()
            })
            conv_id = conv_response.json()["conversation_id"]
            
            results = []
            for i in range(requests_per_worker):
                start_time = time.time()
                
                response = requests.post(f"{self.api_url}/chat", json={
                    "conversation_id": conv_id,
                    "message": f"Worker {worker_id} request {i}: Explain machine learning briefly.",
                    "model": self.get_first_model()
                })
                
                if response.status_code == 200:
                    data = response.json()
                    results.append({
                        'worker_id': worker_id,
                        'request_id': i,
                        'response_time_ms': data.get('response_time_ms', 0),
                        'estimated_tokens': data.get('estimated_tokens', 0),
                        'wall_time': (time.time() - start_time) * 1000
                    })
            
            return results
        
        # Execute concurrent requests
        start_time = time.time()
        with ThreadPoolExecutor(max_workers=num_concurrent) as executor:
            futures = [executor.submit(worker, i) for i in range(num_concurrent)]
            all_results = []
            for future in as_completed(futures):
                all_results.extend(future.result())
        
        total_time = time.time() - start_time
        
        return {
            'results': all_results,
            'total_time': total_time,
            'throughput': len(all_results) / total_time
        }

    def get_first_model(self):
        """Get the first available model."""
        response = requests.get(f"{self.api_url}/models")
        models = response.json().get("models", [])
        return models[0] if models else "default-model"

    def print_statistics(self, data):
        """Print benchmark statistics."""
        if 'response_times' in data:
            # Single request benchmark
            times = data['response_times']
            tokens = data['tokens_generated']
            tps = data['tokens_per_second']
            
            print(f"\nSequential Benchmark Results:")
            print(f"Requests completed: {len(times)}")
            print(f"Response time - Mean: {statistics.mean(times):.1f}ms, "
                  f"Median: {statistics.median(times):.1f}ms, "
                  f"Min: {min(times):.1f}ms, Max: {max(times):.1f}ms")
            print(f"Tokens generated - Total: {sum(tokens)}, "
                  f"Mean: {statistics.mean(tokens):.1f}")
            if tps:
                print(f"Tokens/sec - Mean: {statistics.mean(tps):.1f}, "
                      f"Best: {max(tps):.1f}")
        
        elif 'results' in data:
            # Concurrent request benchmark
            results = data['results']
            times = [r['response_time_ms'] for r in results]
            wall_times = [r['wall_time'] for r in results]
            tokens = [r['estimated_tokens'] for r in results]
            
            print(f"\nConcurrent Benchmark Results:")
            print(f"Total requests: {len(results)}")
            print(f"Total time: {data['total_time']:.2f}s")
            print(f"Throughput: {data['throughput']:.2f} requests/sec")
            print(f"API response time - Mean: {statistics.mean(times):.1f}ms, "
                  f"Median: {statistics.median(times):.1f}ms")
            print(f"Wall clock time - Mean: {statistics.mean(wall_times):.1f}ms, "
                  f"Median: {statistics.median(wall_times):.1f}ms")
            print(f"Total tokens: {sum(tokens)}")

if __name__ == "__main__":
    benchmark = LlamaChatBenchmark()
    
    # Run sequential benchmark
    sequential_results = benchmark.benchmark_single_requests(5)
    benchmark.print_statistics(sequential_results)
    
    # Run concurrent benchmark
    concurrent_results = benchmark.benchmark_concurrent_requests(3, 2)
    benchmark.print_statistics(concurrent_results)
```

---

## Support and Contributing

**API Issues:** Report API bugs and feature requests on [GitHub Issues](https://github.com/ukkit/llama-chat/issues)

**Performance Issues:** Use the metrics endpoints to gather performance data when reporting issues

**API Contributions:** Submit pull requests for API improvements

**Documentation:** Help improve this API documentation

**Integration Examples:** Share your API integration examples and use cases

---

*This API documentation is for llama-chat with llama.cpp integration. For the latest updates, check the [GitHub repository](https://github.com/ukkit/llama-chat).*