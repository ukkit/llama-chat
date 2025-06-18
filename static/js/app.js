/**
 * Enhanced Chat Application with Progressive Model Switching
 * Compatible with both original and enhanced Flask backends
 * Clean version - complete replacement for app.js
 */

// Global variables
let currentConversationId = null;
let availableModels = [];
let currentModel = null;
let isLoading = false;
let isModelSwitching = false;
let messageStartTime = null;
let hasEnhancedBackend = false;

// Initialize marked with options
function initializeMarked() {
    marked.setOptions({
        highlight: function(code, lang) {
            if (lang && hljs.getLanguage(lang)) {
                try {
                    return hljs.highlight(code, { language: lang }).value;
                } catch (err) {}
            }
            try {
                return hljs.highlightAuto(code).value;
            } catch (err) {
                return code;
            }
        },
        breaks: true,
        gfm: true
    });

    // Custom renderer for code blocks with copy buttons
    const renderer = new marked.Renderer();
    renderer.code = function(code, infostring, escaped) {
        const lang = (infostring || '').match(/\S*/)[0];
        const highlightedCode = this.options.highlight ?
            this.options.highlight(code, lang) :
            escapeHtml(code);

        const langDisplay = lang ? lang : 'text';
        const codeId = 'code-' + Math.random().toString(36).substr(2, 9);

        return `<pre><div class="code-block-header"><span class="code-language">${langDisplay}</span><button class="code-copy-btn" onclick="copyCodeBlock('${codeId}')" title="Copy code">📋 Copy</button></div><code id="${codeId}" class="hljs ${lang || ''}">${highlightedCode}</code></pre>`;
    };

    marked.use({ renderer });
}

// Process thinking tags in content
function processThinkingTags(content) {
    const thinkRegex = /<think>([\s\S]*?)<\/think>/gi;
    return content.replace(thinkRegex, function(match, thinkingContent) {
        const cleanedContent = thinkingContent.trim();
        let processedThinking;
        try {
            processedThinking = marked.parseInline(cleanedContent);
        } catch (error) {
            processedThinking = escapeHtml(cleanedContent).replace(/\n/g, '<br>');
        }
        return `<div class="thinking-content" data-thinking="true">${processedThinking}</div>`;
    });
}

// Backend compatibility detection
async function detectBackendCapabilities() {
    try {
        const response = await fetch('/api/models/available');
        if (response.ok) {
            hasEnhancedBackend = true;
            console.log('Enhanced backend detected');
            return true;
        }
    } catch (error) {
        // Enhanced backend not available
    }

    hasEnhancedBackend = false;
    console.log('Using original backend compatibility mode');
    return false;
}

// Load available models with compatibility
async function loadAvailableModels() {
    try {
        await detectBackendCapabilities();

        if (hasEnhancedBackend) {
            // Use enhanced endpoint
            const response = await fetch('/api/models/available');

            if (!response.ok) {
                throw new Error(`HTTP ${response.status}: ${response.statusText}`);
            }

            const data = await response.json();
            availableModels = data.models || [];
            currentModel = data.current_model;

            console.log(`Loaded ${availableModels.length} available models:`, availableModels);
        } else {
            // Fallback to original endpoint
            const response = await fetch('/api/models');

            if (!response.ok) {
                throw new Error(`HTTP ${response.status}: ${response.statusText}`);
            }

            const data = await response.json();

            // Convert original format to enhanced format
            availableModels = (data.models || []).map(modelName => ({
                name: modelName,
                file_path: modelName,
                size_mb: 0,
                size_bytes: 0
            }));

            currentModel = data.models && data.models.length > 0 ? data.models[0] : null;
            console.log(`Loaded ${availableModels.length} models from original backend:`, availableModels);
        }

        console.log('Current model:', currentModel);
        return { models: availableModels, currentModel };
    } catch (error) {
        console.error('Error loading available models:', error);
        throw error;
    }
}

// Switch model (enhanced backend only)
async function switchModel(modelName) {
    if (!hasEnhancedBackend) {
        showNotification('Model switching requires enhanced backend. Please update your Flask app.', 'warning', 5000);
        return false;
    }

    try {
        console.log(`Switching to model: ${modelName}`);
        showModelSwitching(true);

        const response = await fetch('/api/models/switch', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ model_name: modelName })
        });

        const data = await response.json();

        if (response.ok && data.success) {
            currentModel = data.current_model;
            console.log(`Successfully switched to: ${modelName}`);
            updateModelSelectUI();
            showNotification(`Successfully switched to ${modelName}`, 'success');
            return true;
        } else {
            throw new Error(data.error || 'Failed to switch model');
        }
    } catch (error) {
        console.error('Error switching model:', error);
        showNotification(`Failed to switch model: ${error.message}`, 'error');
        return false;
    } finally {
        showModelSwitching(false);
    }
}

// Update model select UI
function updateModelSelectUI() {
    const modelSelect = document.getElementById('modelSelect');
    modelSelect.innerHTML = '';

    if (availableModels.length === 0) {
        const option = document.createElement('option');
        option.value = '';
        option.textContent = 'No models available';
        option.disabled = true;
        modelSelect.appendChild(option);
        return;
    }

    // Add available models
    availableModels.forEach(model => {
        const option = document.createElement('option');
        option.value = model.name;

        if (hasEnhancedBackend && model.size_mb > 0) {
            option.textContent = `${model.name} (${model.size_mb}MB)`;
        } else {
            option.textContent = model.name;
        }

        // Mark current model as selected
        if (currentModel && (currentModel === model.name || currentModel.includes(model.name.replace('.gguf', '')))) {
            option.selected = true;
        }

        modelSelect.appendChild(option);
    });

    updateCurrentModelDisplay();
}

// Update current model display
function updateCurrentModelDisplay() {
    const currentModelDisplay = document.getElementById('currentModelDisplay');
    if (currentModelDisplay) {
        if (currentModel) {
            const modelInfo = availableModels.find(m =>
                currentModel === m.name || currentModel.includes(m.name.replace('.gguf', ''))
            );
            if (modelInfo && hasEnhancedBackend && modelInfo.size_mb > 0) {
                currentModelDisplay.textContent = `${modelInfo.name} (${modelInfo.size_mb}MB)`;
            } else {
                currentModelDisplay.textContent = currentModel;
            }
        } else {
            currentModelDisplay.textContent = 'No model loaded';
        }
    }
}

// Show model switching UI
function showModelSwitching(switching) {
    isModelSwitching = switching;
    const modelSelect = document.getElementById('modelSelect');
    const sendBtn = document.getElementById('sendBtn');
    const messageInput = document.getElementById('messageInput');

    // Show overlay if enhanced backend
    const overlay = document.getElementById('modelSwitchingOverlay');
    if (overlay) {
        overlay.style.display = switching ? 'flex' : 'none';
    }

    if (switching) {
        modelSelect.disabled = true;
        sendBtn.disabled = true;
        sendBtn.textContent = 'Switching Model...';
        messageInput.disabled = true;
        messageInput.placeholder = 'Switching model, please wait...';
    } else {
        modelSelect.disabled = false;
        if (!isLoading) {
            sendBtn.disabled = false;
            sendBtn.textContent = 'Send';
            messageInput.disabled = false;
            messageInput.placeholder = 'Type your message...';
        }
    }
}

// Check server status
async function checkServerStatus() {
    try {
        if (hasEnhancedBackend) {
            const response = await fetch('/api/server/status');
            const data = await response.json();
            return data;
        } else {
            // Fallback check using original endpoints
            const response = await fetch('/api/models');
            if (response.ok) {
                const data = await response.json();
                return {
                    server_running: true,
                    current_model: data.models && data.models.length > 0 ? data.models[0] : null
                };
            }
            return { server_running: false, current_model: null };
        }
    } catch (error) {
        console.error('Error checking server status:', error);
        return { server_running: false, current_model: null };
    }
}

// Enhanced notification system
function showNotification(message, type = 'info', duration = 3000) {
    const existingNotifications = document.querySelectorAll('.notification');
    if (existingNotifications.length > 3) {
        existingNotifications[0].remove();
    }

    const notification = document.createElement('div');
    notification.className = `notification notification-${type}`;
    notification.style.cssText = `
        position: fixed; top: ${20 + existingNotifications.length * 60}px; right: 20px;
        padding: 12px 20px; border-radius: 6px;
        font-family: inherit; font-size: 13px;
        z-index: 1000; max-width: 350px;
        box-shadow: 0 4px 12px rgba(0,0,0,0.3);
        color: white; font-weight: 500;
        transform: translateX(100%);
        transition: transform 0.3s ease;
    `;

    switch (type) {
        case 'success':
            notification.style.background = '#238636';
            break;
        case 'error':
            notification.style.background = '#da3633';
            break;
        case 'warning':
            notification.style.background = '#bf8700';
            break;
        default:
            notification.style.background = '#0969da';
    }

    notification.textContent = message;
    document.body.appendChild(notification);

    setTimeout(() => {
        notification.style.transform = 'translateX(0)';
    }, 10);

    setTimeout(() => {
        notification.style.transform = 'translateX(100%)';
        setTimeout(() => {
            if (notification.parentNode) {
                notification.parentNode.removeChild(notification);
            }
        }, 300);
    }, duration);
}

// Initialize the app
async function init() {
    console.log('Initializing enhanced llama-chat with compatibility detection...');

    initializeMarked();

    const modelSelect = document.getElementById('modelSelect');
    modelSelect.innerHTML = '<option value="">Loading models...</option>';

    try {
        await loadAvailableModels();
        updateModelSelectUI();
        await loadConversations();

        const serverStatus = await checkServerStatus();
        if (!serverStatus.server_running) {
            showNotification('llama.cpp server may not be running. Some features may not work.', 'warning', 5000);
        }

        if (hasEnhancedBackend) {
            showNotification('Enhanced backend detected - full model switching available!', 'success');
        } else {
            showNotification('Using compatibility mode - upgrade Flask app for model switching', 'info', 5000);
        }

        console.log('Initialization complete');
    } catch (error) {
        console.error('Initialization error:', error);
        showNotification('Failed to initialize application. Check console for details.', 'error', 5000);

        const modelSelect = document.getElementById('modelSelect');
        modelSelect.innerHTML = '<option value="">Error loading models</option>';
    }
}

// Model selection handler
async function onModelChange() {
    const modelSelect = document.getElementById('modelSelect');
    const selectedModel = modelSelect.value;

    if (!selectedModel || isModelSwitching || isLoading) {
        return;
    }

    if (!hasEnhancedBackend) {
        showNotification('Model switching requires enhanced backend. Current selection noted for new conversations.', 'info');
        return;
    }

    const isCurrentModel = currentModel && (
        currentModel === selectedModel ||
        currentModel.includes(selectedModel.replace('.gguf', ''))
    );

    if (isCurrentModel) {
        console.log('Model already loaded:', selectedModel);
        return;
    }

    const success = await switchModel(selectedModel);

    if (!success) {
        updateModelSelectUI();
    }
}

// Fixed loadConversations function
async function loadConversations() {
    try {
        console.log('Loading conversations...');
        const response = await fetch('/api/conversations');
        console.log('Conversations response status:', response.status, response.statusText);

        if (!response.ok) {
            console.error('Response not OK:', response.status, response.statusText);
            throw new Error(`HTTP error! status: ${response.status}`);
        }

        const data = await response.json();
        console.log('Conversations response data:', data);

        // Check if the response has the expected structure
        if (!data.success) {
            throw new Error(data.error || 'Failed to load conversations');
        }

        const conversationsList = document.getElementById('conversationsList');
        conversationsList.innerHTML = '';

        // Check if conversations array exists
        if (!data.conversations || !Array.isArray(data.conversations)) {
            console.warn('No conversations array in response');
            return;
        }

        data.conversations.forEach(conv => {
            const div = document.createElement('div');
            div.className = 'conversation-item';
            div.onclick = () => loadConversation(conv.id);

            const date = new Date(conv.updated_at).toLocaleDateString();

            let modelDisplay = conv.model;
            if (hasEnhancedBackend && conv.model_file) {
                modelDisplay = conv.model_file;
            }

            div.innerHTML = `
                <div class="conversation-title" data-conv-id="${conv.id}" onclick="event.stopPropagation();" ondblclick="startRename(${conv.id})">${escapeHtml(conv.title)}</div>
                <div class="conversation-meta">${modelDisplay} • ${date}</div>
                <div class="conversation-actions">
                    <button class="conversation-edit" onclick="event.stopPropagation(); startRename(${conv.id})" title="Rename">✏</button>
                    <button class="conversation-delete" onclick="event.stopPropagation(); deleteConversation(${conv.id})" title="Delete">×</button>
                </div>
            `;

            conversationsList.appendChild(div);
        });

        console.log(`Loaded ${data.conversations.length} conversations`);

    } catch (error) {
        console.error('Error loading conversations:', error);
        showNotification('Failed to load conversations', 'error');
    }
}

// Fixed createNewChat function
async function createNewChat() {
    try {
        console.log('Creating new chat...');

        // Get selected model for enhanced backend
        const selectedModel = document.getElementById('modelSelect').value;
        console.log('Selected model:', selectedModel);

        const requestBody = {
            title: 'New Chat'
        };

        // Add model info if we have enhanced backend
        if (hasEnhancedBackend && selectedModel) {
            requestBody.model = selectedModel;
            requestBody.model_file = selectedModel;
        }

        console.log('Request body:', requestBody);

        const response = await fetch('/api/conversations', {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json'
            },
            body: JSON.stringify(requestBody)
        });

        console.log('Create conversation response status:', response.status);

        if (!response.ok) {
            // Try to get error details from response
            let errorMessage = `HTTP error! status: ${response.status}`;
            try {
                const errorData = await response.json();
                if (errorData.error) {
                    errorMessage = errorData.error;
                }
            } catch (e) {
                // If we can't parse JSON, use the status text
                errorMessage = `HTTP ${response.status}: ${response.statusText}`;
            }
            throw new Error(errorMessage);
        }

        const data = await response.json();
        console.log('Create conversation response data:', data);

        if (!data.success) {
            throw new Error(data.error || 'Failed to create conversation');
        }

        if (!data.conversation_id) {
            throw new Error('No conversation_id in response');
        }

        console.log('Created conversation ID:', data.conversation_id);

        // Reload conversations list
        await loadConversations();

        // Load the new conversation
        await loadConversation(data.conversation_id);

    } catch (error) {
        console.error('Error creating new chat:', error);
        showNotification(`Failed to create new chat: ${error.message}`, 'error');
    }
}

// Fixed loadConversation function
async function loadConversation(conversationId) {
    try {
        console.log('Loading conversation ID:', conversationId);

        if (!conversationId) {
            throw new Error('No conversation ID provided');
        }

        const response = await fetch(`/api/conversations/${conversationId}`);
        console.log('Load conversation response status:', response.status);

        if (!response.ok) {
            let errorMessage = `HTTP error! status: ${response.status}`;
            try {
                const errorData = await response.json();
                if (errorData.error) {
                    errorMessage = errorData.error;
                }
            } catch (e) {
                errorMessage = `HTTP ${response.status}: ${response.statusText}`;
            }
            throw new Error(errorMessage);
        }

        const data = await response.json();
        console.log('Load conversation response data:', data);

        // Check if response indicates an error
        if (!data.success) {
            throw new Error(data.error || 'Failed to load conversation');
        }

        // Check if conversation data exists
        if (!data.conversation) {
            console.error('No conversation data in response:', data);
            throw new Error('No conversation data received');
        }

        currentConversationId = conversationId;

        document.getElementById('chatTitle').textContent = data.conversation.title;
        document.getElementById('inputContainer').style.display = 'flex';

        // Handle model switching for enhanced backend
        if (hasEnhancedBackend) {
            const conversationModel = data.conversation.model_file || data.conversation.model;
            if (conversationModel && conversationModel !== currentModel) {
                const modelExists = availableModels.some(m => m.name === conversationModel);
                if (modelExists) {
                    console.log(`Conversation uses ${conversationModel}, current model is ${currentModel}`);

                    if (confirm(`This conversation was created with ${conversationModel}. Switch to this model?`)) {
                        const switchSuccess = await switchModel(conversationModel);
                        if (!switchSuccess) {
                            showNotification(`Failed to switch to ${conversationModel}. Using current model.`, 'warning');
                        }
                    }
                } else {
                    showNotification(`Model ${conversationModel} not found. Using current model.`, 'warning');
                }
            }
        }

        // Update model select UI
        const modelSelect = document.getElementById('modelSelect');
        if (modelSelect) {
            const conversationModel = hasEnhancedBackend ?
                (data.conversation.model_file || data.conversation.model) :
                data.conversation.model;
            modelSelect.value = conversationModel;
        }

        // Update active conversation in sidebar
        document.querySelectorAll('.conversation-item').forEach(item => {
            item.classList.remove('active');
        });
        document.querySelector(`[onclick*="${conversationId}"]`)?.classList.add('active');

        // Clear and populate chat
        const chatContainer = document.getElementById('chatContainer');
        chatContainer.innerHTML = '';

        // Add messages if they exist
        if (data.messages && Array.isArray(data.messages)) {
            data.messages.forEach(message => {
                addMessageToChat(
                    message.role,
                    message.content,
                    message.model,
                    message.timestamp,
                    message.response_time_ms,
                    message.estimated_tokens,
                    hasEnhancedBackend ? message.model_file : null
                );
            });
        }

        document.getElementById('messageInput').focus();

    } catch (error) {
        console.error('Error loading conversation:', error);
        showNotification(`Failed to load conversation: ${error.message}`, 'error');
    }
}

// Send message
async function sendMessage() {
    if (isLoading || isModelSwitching || !currentConversationId) return;

    const messageInput = document.getElementById('messageInput');
    const message = messageInput.value.trim();
    const selectedModel = document.getElementById('modelSelect').value;

    if (!message) return;

    const serverStatus = await checkServerStatus();
    if (!serverStatus.server_running) {
        showNotification('llama.cpp server is not running. Please start the server.', 'error');
        return;
    }

    messageStartTime = Date.now();

    addMessageToChat('user', message, selectedModel, null, null, null,
                     hasEnhancedBackend ? selectedModel : null);
    messageInput.value = '';
    autoResize(messageInput);

    isLoading = true;
    document.getElementById('sendBtn').disabled = true;
    document.getElementById('sendBtn').textContent = 'Thinking...';

    const loadingDiv = document.createElement('div');
    loadingDiv.className = 'loading';
    loadingDiv.textContent = 'Thinking...';
    document.getElementById('chatContainer').appendChild(loadingDiv);
    scrollToBottom();

    try {
        const requestBody = {
            conversation_id: currentConversationId,
            message: message,
            model: selectedModel
        };

        if (hasEnhancedBackend) {
            requestBody.model_file = selectedModel;
        }

        const response = await fetch('/api/chat', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify(requestBody)
        });

        const data = await response.json();
        const responseTime = messageStartTime ? Date.now() - messageStartTime : 0;

        loadingDiv.remove();

        addMessageToChat(
            'assistant',
            data.response,
            data.model,
            null,
            responseTime,
            data.estimated_tokens,
            hasEnhancedBackend ? data.model_file : null
        );

        if (hasEnhancedBackend && data.model_file && data.model_file !== currentModel) {
            currentModel = data.model_file;
            updateModelSelectUI();
        }

        await loadConversations();

    } catch (error) {
        loadingDiv.remove();
        console.error('Chat error:', error);
        addMessageToChat('assistant', 'Error: Could not get response from llama.cpp server');
        showNotification('Failed to get response from server', 'error');
    } finally {
        isLoading = false;
        if (!isModelSwitching) {
            document.getElementById('sendBtn').disabled = false;
            document.getElementById('sendBtn').textContent = 'Send';
        }
        messageInput.focus();
        messageStartTime = null;
    }
}

// Add message to chat
function addMessageToChat(role, content, model = null, timestamp = null, responseTime = null, tokens = null, modelFile = null) {
    const chatContainer = document.getElementById('chatContainer');
    const messageDiv = document.createElement('div');
    messageDiv.className = `message ${role}`;

    const time = timestamp ? new Date(timestamp).toLocaleTimeString() : new Date().toLocaleTimeString();

    let modelInfo = '';
    if (model && role === 'assistant') {
        if (hasEnhancedBackend && modelFile) {
            const modelName = modelFile.replace('.gguf', '');
            modelInfo = ` • ${modelName}`;
        } else {
            modelInfo = ` • ${model}`;
        }
    }

    // Combine stats and time/model into single line
    let combinedMeta = `<span class="meta-time">${time}${modelInfo}</span>`;

    if (role === 'assistant' && (responseTime || tokens)) {
        const stats = [];
        if (responseTime) {
            stats.push(`${(responseTime / 1000).toFixed(1)}s`);
        }
        if (tokens) {
            stats.push(`~${tokens} tokens`);
            if (responseTime) {
                const tokensPerSecond = (tokens / (responseTime / 1000)).toFixed(1);
                stats.push(`${tokensPerSecond} tok/s`);
            }
        }
        if (stats.length > 0) {
            combinedMeta += ` • <span class="meta-stats">${stats.join(' • ')}</span>`;
        }
    }

    let contentHtml;
    if (role === 'assistant') {
        try {
            const processedContent = processThinkingTags(content);
            contentHtml = marked.parse(processedContent);
        } catch (error) {
            console.error('Markdown parsing error:', error);
            const processedContent = processThinkingTags(content);
            contentHtml = escapeHtml(processedContent).replace(/\n/g, '<br>');
        }
    } else {
        contentHtml = escapeHtml(content).replace(/\n/g, '<br>');
    }

    messageDiv.innerHTML = `
        <div class="message-content">
            ${contentHtml}
            <div class="message-meta">${combinedMeta}</div>
            <button class="copy-btn" onclick="copyMessage(this)" title="Copy message">📋</button>
        </div>
    `;

    chatContainer.appendChild(messageDiv);

    messageDiv.querySelectorAll('pre code').forEach((block) => {
        hljs.highlightElement(block);
    });

    scrollToBottom();
}

// Copy functions
async function copyCodeBlock(codeId) {
    try {
        const codeElement = document.getElementById(codeId);
        if (!codeElement) return;

        let codeText = codeElement.textContent || codeElement.innerText || '';
        codeText = codeText.trim();

        if (!codeText) {
            throw new Error('No code content found to copy');
        }

        if (navigator.clipboard && window.isSecureContext) {
            await navigator.clipboard.writeText(codeText);
            showCodeCopySuccess(codeId);
        } else {
            const success = copyTextFallback(codeText);
            if (success) {
                showCodeCopySuccess(codeId);
            } else {
                showCodeCopyError(codeId);
            }
        }

    } catch (err) {
        console.error('Code copy failed:', err);
        showCodeCopyError(codeId);
    }
}

function showCodeCopySuccess(codeId) {
    const button = document.querySelector(`button[onclick*="${codeId}"]`);
    if (button) {
        const originalText = button.textContent;
        button.textContent = '✓ Copied';
        button.classList.add('copied');
        showCopyNotification();

        setTimeout(() => {
            button.textContent = originalText;
            button.classList.remove('copied');
        }, 2000);
    }
}

function showCodeCopyError(codeId) {
    const button = document.querySelector(`button[onclick*="${codeId}"]`);
    if (button) {
        const originalText = button.textContent;
        button.textContent = '❌ Failed';
        button.style.color = '#da3633';

        setTimeout(() => {
            button.textContent = originalText;
            button.style.color = '';
        }, 2000);
    }
}

async function copyMessage(button) {
    try {
        const messageContent = button.closest('.message-content');
        const tempDiv = document.createElement('div');
        const clonedContent = messageContent.cloneNode(true);

        const metaDiv = clonedContent.querySelector('.message-meta');
        const statsDiv = clonedContent.querySelector('.message-stats');
        const copyBtn = clonedContent.querySelector('.copy-btn');
        const codeHeaders = clonedContent.querySelectorAll('.code-block-header');
        const thinkingContent = clonedContent.querySelectorAll('.thinking-content');

        if (metaDiv) metaDiv.remove();
        if (statsDiv) statsDiv.remove();
        if (copyBtn) copyBtn.remove();
        codeHeaders.forEach(header => header.remove());
        thinkingContent.forEach(thinking => thinking.remove());

        tempDiv.appendChild(clonedContent);

        let textContent = tempDiv.textContent || tempDiv.innerText || '';
        textContent = textContent.trim();

        if (!textContent) {
            throw new Error('No text content found to copy');
        }

        if (navigator.clipboard && window.isSecureContext) {
            await navigator.clipboard.writeText(textContent);
            showCopySuccess(button);
        } else {
            const success = copyTextFallback(textContent);
            if (success) {
                showCopySuccess(button);
            } else {
                showCopyError(button);
            }
        }

    } catch (err) {
        console.error('Copy failed:', err);
        showCopyError(button);
    }
}

function copyTextFallback(text) {
    try {
        const textArea = document.createElement('textarea');
        textArea.value = text;
        textArea.style.position = 'fixed';
        textArea.style.top = '0';
        textArea.style.left = '0';
        textArea.style.width = '2em';
        textArea.style.height = '2em';
        textArea.style.padding = '0';
        textArea.style.border = 'none';
        textArea.style.outline = 'none';
        textArea.style.boxShadow = 'none';
        textArea.style.background = 'transparent';
        textArea.style.opacity = '0';
        textArea.setAttribute('readonly', '');

        document.body.appendChild(textArea);
        textArea.focus();
        textArea.setSelectionRange(0, textArea.value.length);
        textArea.select();

        const successful = document.execCommand('copy');
        document.body.removeChild(textArea);
        return successful;

    } catch (err) {
        console.error('Fallback copy error:', err);
        return false;
    }
}

function showCopySuccess(button) {
    button.textContent = '✓';
    button.classList.add('copied');
    showCopyNotification();

    setTimeout(() => {
        button.textContent = '📋';
        button.classList.remove('copied');
    }, 2000);
}

function showCopyError(button) {
    button.textContent = '❌';
    button.style.color = '#da3633';

    setTimeout(() => {
        button.textContent = '📋';
        button.style.color = '';
    }, 2000);
}

function showCopyNotification() {
    const notification = document.getElementById('copyNotification');
    if (notification) {
        notification.classList.add('show');
        setTimeout(() => {
            notification.classList.remove('show');
        }, 2000);
    }
}

// Utility functions
function startRename(conversationId) {
    const titleElement = document.querySelector(`[data-conv-id="${conversationId}"]`);
    if (!titleElement || titleElement.querySelector('input')) return;

    const currentTitle = titleElement.textContent;

    const input = document.createElement('input');
    input.type = 'text';
    input.className = 'conversation-title-input';
    input.value = currentTitle;
    input.maxLength = 100;

    const saveRename = async () => {
        const newTitle = input.value.trim();
        if (!newTitle || newTitle === currentTitle) {
            cancelRename();
            return;
        }

        try {
            const response = await fetch(`/api/conversations/${conversationId}`, {
                method: 'PUT',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({ title: newTitle })
            });

            if (response.ok) {
                if (input.parentNode === titleElement) {
                    titleElement.removeChild(input);
                }
                titleElement.textContent = newTitle;

                if (currentConversationId === conversationId) {
                    document.getElementById('chatTitle').textContent = newTitle;
                }

                await loadConversations();
            } else {
                const error = await response.json();
                showNotification(error.error || 'Failed to rename conversation', 'error');
                cancelRename();
            }
        } catch (error) {
            console.error('Error renaming conversation:', error);
            showNotification('Failed to rename conversation', 'error');
            cancelRename();
        }
    };

    const cancelRename = () => {
        if (input.parentNode === titleElement) {
            titleElement.removeChild(input);
        }
        titleElement.textContent = currentTitle;
    };

    input.onblur = saveRename;
    input.onkeydown = (e) => {
        if (e.key === 'Enter') {
            e.preventDefault();
            saveRename();
        } else if (e.key === 'Escape') {
            e.preventDefault();
            cancelRename();
        }
    };

    titleElement.textContent = '';
    titleElement.appendChild(input);
    input.focus();
    input.select();
}

async function deleteConversation(conversationId) {
    if (!confirm('Delete this conversation?')) return;

    try {
        const response = await fetch(`/api/conversations/${conversationId}`, {
            method: 'DELETE'
        });

        if (!response.ok) {
            throw new Error(`HTTP error! status: ${response.status}`);
        }

        if (currentConversationId === conversationId) {
            currentConversationId = null;
            document.getElementById('chatContainer').innerHTML = `
                <div class="no-conversation">
                    <h2>Welcome to llama-chat</h2>
                    <p>Create a new chat to get started</p>
                </div>
            `;
            document.getElementById('inputContainer').style.display = 'none';
            document.getElementById('chatTitle').textContent = 'Select a conversation';
        }

        await loadConversations();
        showNotification('Conversation deleted successfully', 'success');

    } catch (error) {
        console.error('Error deleting conversation:', error);
        showNotification('Failed to delete conversation', 'error');
    }
}

async function searchConversations(event) {
    const query = event.target.value.trim();
    const resultsDiv = document.getElementById('searchResults');

    if (query.length < 2) {
        resultsDiv.style.display = 'none';
        return;
    }

    try {
        const response = await fetch(`/api/search?q=${encodeURIComponent(query)}`);

        if (!response.ok) {
            throw new Error(`HTTP error! status: ${response.status}`);
        }

        const data = await response.json();

        resultsDiv.innerHTML = '';

        if (!data.results || data.results.length === 0) {
            resultsDiv.innerHTML = '<div class="search-result">No results found</div>';
        } else {
            data.results.forEach(result => {
                const div = document.createElement('div');
                div.className = 'search-result';
                div.onclick = () => {
                    loadConversation(result.id);
                    resultsDiv.style.display = 'none';
                    event.target.value = '';
                };

                const preview = result.content.length > 100 ?
                    result.content.substring(0, 100) + '...' : result.content;

                let modelDisplay = result.model;
                if (hasEnhancedBackend && result.model_file) {
                    modelDisplay = result.model_file;
                }

                div.innerHTML = `
                    <div class="search-result-title">${escapeHtml(result.title)}</div>
                    <div class="search-result-content">${escapeHtml(preview)}</div>
                    <div class="search-result-meta">${modelDisplay}</div>
                `;

                resultsDiv.appendChild(div);
            });
        }

        resultsDiv.style.display = 'block';
    } catch (error) {
        console.error('Error searching:', error);
        showNotification('Search failed', 'error');
    }
}

function handleKeyDown(event) {
    if (event.key === 'Enter' && !event.shiftKey) {
        event.preventDefault();
        sendMessage();
    }
}

function autoResize(textarea) {
    textarea.style.height = 'auto';
    textarea.style.height = Math.min(textarea.scrollHeight, 120) + 'px';
}

function scrollToBottom() {
    const chatContainer = document.getElementById('chatContainer');
    chatContainer.scrollTop = chatContainer.scrollHeight;
}

function escapeHtml(text) {
    const div = document.createElement('div');
    div.textContent = text;
    return div.innerHTML;
}

function estimateTokens(text) {
    return Math.ceil(text.length / 4);
}

// Server health monitoring
async function checkServerHealth() {
    try {
        const status = await checkServerStatus();
        const statusIndicators = document.querySelectorAll('.server-status');
        const statusText = document.getElementById('serverStatusText');

        statusIndicators.forEach(indicator => {
            if (status.server_running) {
                indicator.className = 'server-status online';
                indicator.title = `Server online${status.current_model ? ' - ' + status.current_model : ''}`;
            } else {
                indicator.className = 'server-status offline';
                indicator.title = 'Server offline';
            }
        });

        if (statusText) {
            statusText.textContent = status.server_running ? 'Online' : 'Offline';
            statusText.style.color = status.server_running ? '#238636' : '#da3633';
        }

        return status.server_running;
    } catch (error) {
        console.error('Health check failed:', error);

        const statusIndicators = document.querySelectorAll('.server-status');
        const statusText = document.getElementById('serverStatusText');

        statusIndicators.forEach(indicator => {
            indicator.className = 'server-status offline';
            indicator.title = 'Connection error';
        });

        if (statusText) {
            statusText.textContent = 'Error';
            statusText.style.color = '#da3633';
        }

        return false;
    }
}

// Event listeners
document.addEventListener('DOMContentLoaded', function() {
    // Hide search results when clicking outside
    document.addEventListener('click', function(event) {
        const searchBox = document.getElementById('searchBox');
        const searchResults = document.getElementById('searchResults');

        if (searchBox && searchResults &&
            !searchBox.contains(event.target) &&
            !searchResults.contains(event.target)) {
            searchResults.style.display = 'none';
        }
    });

    // Add model selection change handler
    const modelSelect = document.getElementById('modelSelect');
    if (modelSelect) {
        modelSelect.addEventListener('change', onModelChange);
    }

    // Start periodic health checks
    setInterval(checkServerHealth, 30000); // Check every 30 seconds

    // Initial health check
    setTimeout(checkServerHealth, 2000);
});

// Initialize app when page loads
window.addEventListener('load', init);