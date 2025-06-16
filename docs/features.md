# llama-chat 🦙 Features

A comprehensive web interface for llama.cpp with persistent conversation history, advanced markdown rendering, and professional code syntax highlighting.

## 🎯 Core Features

### 💬 **Enhanced Chat Interface**
- **Real-time messaging** with llama.cpp models
- **Professional dark theme UI** with GitHub-inspired design using JetBrains Mono font
- **Auto-resizing input** textarea that adapts to content length
- **Keyboard shortcuts** - Enter to send, Shift+Enter for new line
- **Loading indicators** with "Thinking..." status during AI responses
- **📝 Full Markdown Support** - Rich text rendering for AI responses
- **🎨 Syntax Highlighting** - Code blocks with 190+ language support via Highlight.js

### 🗂️ **Conversation Management**
- **Persistent chat history** stored in SQLite database
- **Multiple conversation support** with sidebar navigation
- **Conversation renaming** - double-click or edit button to rename
- **Conversation deletion** with confirmation dialog
- **Auto-timestamping** with last updated sorting
- **New chat creation** with model selection
- **Model restoration** - automatically restores selected model per conversation

### 🔍 **Search & Discovery**
- **Real-time search** across conversations and message content
- **Search results preview** with conversation context
- **Quick navigation** to search results
- **Fuzzy matching** for flexible search queries

## 🚀 Enhanced Features

### 📋 **Advanced Copy Functionality**
- **Dual copy system**:
  - **Message copy** - hover over any message to reveal copy button (📋)
  - **Code block copy** - dedicated copy buttons for each code block
- **Smart text extraction** - preserves formatting while removing HTML
- **Visual feedback** - copy buttons change to ✓ when successful
- **Toast notifications** for copy confirmations
- **Cross-browser support** with fallback for older browsers
- **Clean code extraction** - copies raw code without syntax highlighting markup

### 📝 **Markdown Rendering Engine**
- **GitHub-Flavored Markdown** support with marked.js
- **Rich typography** with proper heading hierarchy (H1-H6)
- **Text formatting**: **bold**, *italic*, ~~strikethrough~~
- **Lists**: ordered and unordered with proper nesting
- **Tables** with professional styling and borders
- **Blockquotes** with left border accent styling
- **Links** with hover effects and proper contrast
- **Horizontal rules** for content separation
- **Inline code** with background highlighting
- **Mathematical expressions** support (if enabled)

### 💻 **Advanced Code Support**
- **Syntax highlighting** for 190+ programming languages via Highlight.js
- **Language detection** with automatic highlighting
- **Code block headers** showing language type
- **Individual copy buttons** for each code block
- **GitHub Dark theme** optimized for readability
- **Professional formatting** with proper spacing and line numbers
- **Multi-language support** including:
  - Python, JavaScript, TypeScript, Java, C++, C#
  - HTML, CSS, SCSS, JSON, YAML, XML
  - SQL, Bash, PowerShell, Dockerfile
  - React, Vue, Angular, Svelte
  - And 180+ more languages

### 📊 **Performance Metrics**
- **Response time tracking** - displays time taken for each AI response
- **Token counting** - estimates and displays token usage
- **Tokens per second** calculation for performance insights
- **Database metrics storage** for analytics and optimization
- **Real-time performance display** under each assistant message

### 🤖 **llama.cpp Integration**
- **Dynamic model detection** from llama.cpp server
- **Model selection dropdown** with auto-refresh
- **Model-specific configuration** support
- **Multi-model conversations** - switch models between messages
- **Connection status monitoring** with error handling
- **OpenAI-compatible API** integration for seamless communication

## 🎨 **Enhanced User Experience**

### 🖥️ **Professional Interface Design**
- **Code editor aesthetic** inspired by VS Code and GitHub
- **Consistent typography** with JetBrains Mono font family
- **Color-coded elements**:
  - Headers in gradient blues (#58a6ff to #a5d7ff)
  - Code in amber (#ffa657)
  - Emphasis in light blue (#a5d7ff)
  - Links in GitHub blue (#58a6ff)
- **Smooth animations** and transitions
- **Hover effects** for interactive elements
- **Loading states** with progress indicators
- **Visual hierarchy** with proper spacing and contrast

### 💡 **Content Presentation**
- **Structured messaging** with clear role distinction
- **Code block presentation**:
  - Language labels in headers
  - Copy buttons for easy code extraction
  - Syntax highlighting for readability
  - Overflow handling for long code
- **Table formatting** with borders and header styling
- **Quote styling** with left border accent
- **List formatting** with proper indentation

## ⚙️ Advanced Configuration

### 🔧 **llama.cpp Integration**
- **Customizable API endpoints** via environment variables
- **Timeout configuration** for connection and response handling
- **Advanced model parameters** for fine-tuning AI responses
- **Custom system prompts** for personality customization
- **GPU acceleration support** when available
- **CUDA/Metal optimization** for supported hardware

### 🎛️ **Performance Optimization**
- **Threading support** for concurrent request handling
- **Context history limiting** to optimize memory usage
- **Connection pooling** and keep-alive settings
- **Memory management** optimization options
- **Configurable batch processing**
- **Model caching** and warm-up strategies

*For detailed configuration options, see [config.md](config.md)*

### 📁 **Database Features**
- **SQLite backend** with optimized schema
- **Indexed queries** for fast search and retrieval
- **Foreign key constraints** for data integrity
- **Automatic schema migration** and initialization
- **Conversation statistics** tracking
- **Message metadata** storage (timestamps, models, metrics)

## 🛡️ **Security & Reliability**

### 🔐 **Security**
- **SQL injection prevention** with parameterized queries
- **Input validation** and sanitization
- **XSS protection** with HTML escaping for user content
- **Markdown security** - safe rendering of untrusted content
- **CSRF token support** (configurable)
- **Environment variable configuration** for sensitive data

### 🛠️ **Error Handling**
- **Graceful degradation** when llama.cpp is unavailable
- **Connection timeout handling** with user feedback
- **API error recovery** with informative error messages
- **Database error handling** with transaction rollback
- **Client-side error notifications** with auto-dismiss
- **Markdown parsing fallback** - graceful handling of malformed markdown

### 📱 **Responsive Design**
- **Mobile-friendly interface** with touch-optimized controls
- **Adaptive layout** that works on all screen sizes
- **Accessible design** with proper contrast and semantic HTML
- **Keyboard navigation** support
- **Screen reader compatibility**
- **Touch-friendly copy buttons** for mobile devices

## 🏗️ **Architecture & Code Organization**

### 📁 **File Structure**
```
llama-chat/
├── app.py                 # Flask backend with llama.cpp integration
├── config.json           # llama.cpp and model configuration
├── llama-chat.conf        # Service configuration
├── chat-manager.sh        # Process management script
├── templates/
│   └── index.html        # Main HTML template
├── static/
│   ├── css/
│   │   └── styles.css    # Organized CSS styling
│   └── js/
│       └── app.js        # Modular JavaScript
└── models/                # Directory for .gguf model files
```

### 🔧 **Modular Design**
- **Separation of concerns** - HTML structure, CSS styling, JS logic
- **Maintainable codebase** with organized file structure
- **Reusable components** for easy extension
- **Clean APIs** between frontend and backend
- **Version control friendly** with isolated changes

### 🌐 **Frontend Architecture**
- **Vanilla JavaScript** with modern ES6+ features
- **No framework dependencies** for fast loading
- **External library integration**:
  - **marked.js** for markdown parsing
  - **highlight.js** for syntax highlighting
- **Modular function organization**
- **Event-driven architecture**
- **Progressive enhancement** approach

## 📊 **Analytics & Insights**

### 📈 **Conversation Analytics**
- **Message count tracking** per conversation
- **Average response times** calculation
- **Token usage statistics** and trends
- **Model performance comparison** across conversations
- **Usage patterns** and conversation metrics
- **Markdown usage analytics** - tracking formatted content

### 🔍 **Search Analytics**
- **Search result relevance** scoring
- **Popular search terms** tracking
- **Conversation discovery** patterns
- **Content indexing** for fast retrieval

## 🚀 **Technical Specifications**

### 💻 **Backend (Flask + llama.cpp)**
- **Python 3.8+** compatibility
- **Flask framework** with threading support
- **llama.cpp server integration** via HTTP API
- **SQLite database** with WAL mode for performance
- **RESTful API** design with JSON responses
- **Modular architecture** with separation of concerns
- **Configuration management** via JSON files

### 🌐 **Frontend Technologies**
- **HTML5** with semantic markup
- **CSS3** with modern features (Grid, Flexbox, Custom Properties)
- **Vanilla JavaScript** with ES6+ async/await
- **External Libraries**:
  - **marked.js 5.1.1** - Fast markdown parser
  - **highlight.js 11.9.0** - Syntax highlighting
- **Web APIs integration** (Clipboard, Fetch, etc.)
- **Accessibility best practices** (ARIA, semantic HTML)

### 🗄️ **Database Schema**
- **Normalized design** with proper relationships
- **Optimized indexes** for query performance
- **Constraint enforcement** for data integrity
- **Migration support** for schema updates
- **Backup-friendly** design with SQLite

## 🎯 **Use Cases**

### 👩‍💻 **Development & Programming**
- **AI-assisted coding** with syntax-highlighted code examples
- **Code documentation** with markdown formatting
- **Code review** sessions with formatted explanations
- **Algorithm discussions** with mathematical notation
- **API documentation** with structured formatting
- **Technical tutorials** with step-by-step code examples

### 📚 **Research & Learning**
- **Interactive learning** with formatted educational content
- **Research papers** discussion with citation formatting
- **Mathematical explanations** with proper notation
- **Scientific documentation** with structured presentations
- **Note-taking** with rich formatting options
- **Knowledge base building** with organized content

### 💼 **Business & Content Creation**
- **Technical documentation** with professional formatting
- **Meeting notes** with structured layouts
- **Content planning** with organized lists and headers
- **Project documentation** with tables and structured data
- **Training materials** with formatted content
- **Process documentation** with clear step-by-step formatting

### 🎓 **Education & Training**
- **Coding tutorials** with syntax-highlighted examples
- **Technical explanations** with formatted content
- **Learning materials** with structured presentations
- **Assignment help** with proper code formatting
- **Study guides** with organized information hierarchy

---

## 🛠️ **Model Management**

### Supported Model Formats
- **GGUF format** - Primary format for llama.cpp
- **Quantized models** - Q4_0, Q4_1, Q5_0, Q5_1, Q8_0
- **Full precision** - F16, F32 (for high-end systems)

### Model Categories
- **Ultra-fast**: qwen2.5:0.5b, tinyllama (testing and quick responses)
- **Balanced**: phi3-mini, llama3.2:1b (daily use)
- **High-quality**: llama3.1:8b, qwen2.5:7b (resource-intensive tasks)
- **Specialized**: codellama, mistral-nemo (coding, domain-specific)

### Performance Characteristics

| Model Size | RAM Usage | CPU Speed | GPU Speed | Quality |
|------------|-----------|-----------|-----------|---------|
| 0.5B params | ~1GB | 15-30 tok/s | 50-100 tok/s | Good |
| 1B params | ~2GB | 10-20 tok/s | 40-80 tok/s | Very Good |
| 3B params | ~4GB | 5-15 tok/s | 30-60 tok/s | Excellent |
| 7B params | ~8GB | 2-8 tok/s | 20-40 tok/s | Superior |

---

## 🆕 **Recent Updates**

### **v2.0 - llama.cpp Native Integration**
- ✅ **Direct llama.cpp server integration** replacing Ollama dependency
- ✅ **OpenAI-compatible API** for seamless model communication
- ✅ **Enhanced performance metrics** with token/second tracking
- ✅ **Improved model management** with automatic .gguf detection
- ✅ **Better resource optimization** for CPU and GPU usage
- ✅ **Simplified installation** with integrated dependency management

### **Key Improvements**
- **Better performance** with native llama.cpp integration
- **Lower resource usage** optimized for local deployment
- **Enhanced stability** with dedicated server process
- **Improved error handling** and recovery mechanisms
- **Modern web standards** with progressive enhancement

---

*llama-chat now provides the most comprehensive local AI chat experience with llama.cpp, combining powerful conversation capabilities with professional markdown rendering and code syntax highlighting, perfect for technical discussions, coding assistance, and formatted content creation.*