/**
 * Fliliy二手交易平台 WebSocket客户端SDK
 * 用于前端应用集成实时聊天功能
 */

class FliliyWebSocketClient {
    constructor(options = {}) {
        this.serverUrl = options.serverUrl || 'ws://localhost:8080/ws';
        this.jwtToken = options.jwtToken;
        this.autoReconnect = options.autoReconnect !== false;
        this.reconnectInterval = options.reconnectInterval || 5000;
        this.heartbeatInterval = options.heartbeatInterval || 30000;
        
        this.stompClient = null;
        this.connected = false;
        this.reconnectAttempts = 0;
        this.maxReconnectAttempts = options.maxReconnectAttempts || 10;
        this.subscriptions = new Map();
        this.eventHandlers = new Map();
        
        this.heartbeatTimer = null;
        this.reconnectTimer = null;
        
        // 绑定事件处理器
        this.setupEventHandlers();
    }

    /**
     * 设置事件处理器
     */
    setupEventHandlers() {
        // 默认事件处理器
        this.eventHandlers.set('connected', []);
        this.eventHandlers.set('disconnected', []);
        this.eventHandlers.set('error', []);
        this.eventHandlers.set('message', []);
        this.eventHandlers.set('userStatus', []);
        this.eventHandlers.set('readStatus', []);
        this.eventHandlers.set('notification', []);
    }

    /**
     * 连接到WebSocket服务
     */
    connect() {
        if (this.connected) {
            console.warn('WebSocket已经连接');
            return Promise.resolve();
        }

        if (!this.jwtToken) {
            const error = new Error('JWT令牌不能为空');
            this.emit('error', error);
            return Promise.reject(error);
        }

        return new Promise((resolve, reject) => {
            try {
                console.log('正在连接WebSocket:', this.serverUrl);
                
                // 创建WebSocket连接，携带JWT令牌
                const socket = new SockJS(this.serverUrl + '?token=' + encodeURIComponent(this.jwtToken));
                this.stompClient = Stomp.over(socket);

                // 禁用调试日志（生产环境）
                this.stompClient.debug = null;

                this.stompClient.connect({}, 
                    (frame) => {
                        this.connected = true;
                        this.reconnectAttempts = 0;
                        
                        console.log('WebSocket连接成功:', frame);
                        this.emit('connected', frame);
                        
                        // 启动心跳
                        this.startHeartbeat();
                        
                        // 发送用户在线状态
                        this.updateUserStatus('online');
                        
                        resolve(frame);
                    },
                    (error) => {
                        this.connected = false;
                        console.error('WebSocket连接失败:', error);
                        this.emit('error', error);
                        
                        // 自动重连
                        if (this.autoReconnect) {
                            this.scheduleReconnect();
                        }
                        
                        reject(error);
                    }
                );
            } catch (error) {
                this.emit('error', error);
                reject(error);
            }
        });
    }

    /**
     * 断开WebSocket连接
     */
    disconnect() {
        if (!this.connected || !this.stompClient) {
            return Promise.resolve();
        }

        return new Promise((resolve) => {
            // 停止心跳和重连定时器
            this.stopHeartbeat();
            this.stopReconnect();
            
            // 发送用户离线状态
            this.updateUserStatus('offline');
            
            // 断开连接
            this.stompClient.disconnect(() => {
                this.connected = false;
                this.subscriptions.clear();
                
                console.log('WebSocket连接已断开');
                this.emit('disconnected');
                
                resolve();
            });
        });
    }

    /**
     * 订阅聊天室消息
     */
    subscribeToChatRoom(chatRoomId) {
        if (!this.connected || !this.stompClient) {
            throw new Error('WebSocket未连接');
        }

        const destination = '/topic/chat/' + chatRoomId;
        
        if (this.subscriptions.has(destination)) {
            console.warn('已经订阅了聊天室:', chatRoomId);
            return;
        }

        const subscription = this.stompClient.subscribe(destination, (message) => {
            try {
                const messageData = JSON.parse(message.body);
                this.handleChatRoomMessage(chatRoomId, messageData);
            } catch (error) {
                console.error('解析聊天室消息失败:', error);
                this.emit('error', error);
            }
        });

        this.subscriptions.set(destination, subscription);
        console.log('已订阅聊天室:', chatRoomId);
    }

    /**
     * 取消订阅聊天室
     */
    unsubscribeFromChatRoom(chatRoomId) {
        const destination = '/topic/chat/' + chatRoomId;
        const subscription = this.subscriptions.get(destination);
        
        if (subscription) {
            subscription.unsubscribe();
            this.subscriptions.delete(destination);
            console.log('已取消订阅聊天室:', chatRoomId);
        }
    }

    /**
     * 订阅用户私人消息
     */
    subscribeToUserMessages() {
        if (!this.connected || !this.stompClient) {
            throw new Error('WebSocket未连接');
        }

        const destination = '/user/queue/messages';
        
        if (this.subscriptions.has(destination)) {
            console.warn('已经订阅了用户消息');
            return;
        }

        const subscription = this.stompClient.subscribe(destination, (message) => {
            try {
                const messageData = JSON.parse(message.body);
                this.handleUserMessage(messageData);
            } catch (error) {
                console.error('解析用户消息失败:', error);
                this.emit('error', error);
            }
        });

        this.subscriptions.set(destination, subscription);
        console.log('已订阅用户私人消息');
    }

    /**
     * 发送聊天消息
     */
    sendMessage(chatRoomId, message) {
        if (!this.connected || !this.stompClient) {
            throw new Error('WebSocket未连接');
        }

        const destination = '/app/chat/' + chatRoomId + '/send';
        
        try {
            this.stompClient.send(destination, {}, JSON.stringify(message));
            console.log('已发送消息到聊天室', chatRoomId, ':', message);
        } catch (error) {
            console.error('发送消息失败:', error);
            this.emit('error', error);
            throw error;
        }
    }

    /**
     * 发送文本消息
     */
    sendTextMessage(chatRoomId, content) {
        return this.sendMessage(chatRoomId, {
            type: 'TEXT',
            content: content
        });
    }

    /**
     * 发送图片消息
     */
    sendImageMessage(chatRoomId, imageUrl, thumbnailUrl) {
        return this.sendMessage(chatRoomId, {
            type: 'IMAGE',
            content: imageUrl,
            thumbnail: thumbnailUrl
        });
    }

    /**
     * 发送语音消息
     */
    sendVoiceMessage(chatRoomId, voiceUrl, duration) {
        return this.sendMessage(chatRoomId, {
            type: 'VOICE',
            content: voiceUrl,
            duration: duration
        });
    }

    /**
     * 标记消息已读
     */
    markMessagesAsRead(chatRoomId, lastReadMessageId) {
        if (!this.connected || !this.stompClient) {
            throw new Error('WebSocket未连接');
        }

        const destination = '/app/chat/' + chatRoomId + '/read';
        
        try {
            this.stompClient.send(destination, {}, lastReadMessageId || Date.now().toString());
            console.log('已标记聊天室消息为已读:', chatRoomId);
        } catch (error) {
            console.error('标记消息已读失败:', error);
            this.emit('error', error);
            throw error;
        }
    }

    /**
     * 更新用户在线状态
     */
    updateUserStatus(status) {
        if (!this.connected || !this.stompClient) {
            return;
        }

        try {
            this.stompClient.send('/app/user/status', {}, status);
            console.log('已更新用户状态:', status);
        } catch (error) {
            console.error('更新用户状态失败:', error);
        }
    }

    /**
     * 处理聊天室消息
     */
    handleChatRoomMessage(chatRoomId, messageData) {
        console.log('收到聊天室消息:', chatRoomId, messageData);
        
        switch (messageData.type) {
            case 'user_status':
                this.emit('userStatus', messageData);
                break;
            case 'read_status':
                this.emit('readStatus', messageData);
                break;
            default:
                this.emit('message', {
                    chatRoomId: chatRoomId,
                    message: messageData
                });
        }
    }

    /**
     * 处理用户私人消息
     */
    handleUserMessage(messageData) {
        console.log('收到用户私人消息:', messageData);
        
        switch (messageData.type) {
            case 'error':
                this.emit('error', new Error(messageData.message));
                break;
            case 'notification':
                this.emit('notification', messageData);
                break;
            default:
                this.emit('message', { message: messageData });
        }
    }

    /**
     * 启动心跳机制
     */
    startHeartbeat() {
        this.stopHeartbeat();
        
        this.heartbeatTimer = setInterval(() => {
            if (this.connected && this.stompClient) {
                try {
                    this.stompClient.send('/app/user/status', {}, 'heartbeat');
                } catch (error) {
                    console.error('心跳发送失败:', error);
                }
            }
        }, this.heartbeatInterval);
    }

    /**
     * 停止心跳机制
     */
    stopHeartbeat() {
        if (this.heartbeatTimer) {
            clearInterval(this.heartbeatTimer);
            this.heartbeatTimer = null;
        }
    }

    /**
     * 计划重连
     */
    scheduleReconnect() {
        if (this.reconnectAttempts >= this.maxReconnectAttempts) {
            console.error('达到最大重连次数，停止重连');
            this.emit('error', new Error('达到最大重连次数'));
            return;
        }

        this.stopReconnect();
        
        this.reconnectAttempts++;
        const delay = this.reconnectInterval * Math.pow(2, Math.min(this.reconnectAttempts - 1, 5)); // 指数退避
        
        console.log(`将在${delay}ms后尝试第${this.reconnectAttempts}次重连...`);
        
        this.reconnectTimer = setTimeout(() => {
            this.connect().catch((error) => {
                console.error('重连失败:', error);
            });
        }, delay);
    }

    /**
     * 停止重连
     */
    stopReconnect() {
        if (this.reconnectTimer) {
            clearTimeout(this.reconnectTimer);
            this.reconnectTimer = null;
        }
    }

    /**
     * 注册事件处理器
     */
    on(event, handler) {
        if (!this.eventHandlers.has(event)) {
            this.eventHandlers.set(event, []);
        }
        this.eventHandlers.get(event).push(handler);
    }

    /**
     * 移除事件处理器
     */
    off(event, handler) {
        if (this.eventHandlers.has(event)) {
            const handlers = this.eventHandlers.get(event);
            const index = handlers.indexOf(handler);
            if (index > -1) {
                handlers.splice(index, 1);
            }
        }
    }

    /**
     * 触发事件
     */
    emit(event, data) {
        if (this.eventHandlers.has(event)) {
            const handlers = this.eventHandlers.get(event);
            handlers.forEach(handler => {
                try {
                    handler(data);
                } catch (error) {
                    console.error('事件处理器执行失败:', event, error);
                }
            });
        }
    }

    /**
     * 获取连接状态
     */
    isConnected() {
        return this.connected;
    }

    /**
     * 设置JWT令牌
     */
    setJwtToken(token) {
        this.jwtToken = token;
    }

    /**
     * 销毁客户端
     */
    destroy() {
        return this.disconnect().then(() => {
            this.eventHandlers.clear();
            this.subscriptions.clear();
            this.stompClient = null;
        });
    }
}

// 导出类（如果在模块环境中使用）
if (typeof module !== 'undefined' && module.exports) {
    module.exports = FliliyWebSocketClient;
}

// 全局变量（如果在浏览器中使用）
if (typeof window !== 'undefined') {
    window.FliliyWebSocketClient = FliliyWebSocketClient;
}