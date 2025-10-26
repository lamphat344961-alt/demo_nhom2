import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/route_provider.dart';
import '../../models/chat_message.dart';
import '../../core/services/gemini_service.dart';
import '../../core/services/speech_service.dart';
import '../../core/services/tts_service.dart';
import 'deliveries_tab.dart';
import 'map_tab.dart';
import 'account_tab.dart';

class DriverHomeScreen extends StatefulWidget {
  const DriverHomeScreen({super.key});

  @override
  State<DriverHomeScreen> createState() => _DriverHomeScreenState();
}

class _DriverHomeScreenState extends State<DriverHomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const DeliveriesTab(),
    const MapTab(),
    const DriverAccountTab(),
  ];

  // ==================== CHATBOX STATE ====================
  bool _isChatOpen = false;
  bool _isLoading = false;
  bool _isListening = false;
  bool _isTTSEnabled = true;

  final TextEditingController _msgController = TextEditingController();
  final List<ChatMessage> _messages = [];
  final ScrollController _scrollController = ScrollController();

  // Vị trí chatbox (draggable)
  double _chatPositionX = 20;
  double _chatPositionY = 80;

  // Services
  late final GeminiService _geminiService;
  late final SpeechService _speechService;
  late final TTSService _ttsService;

  @override
  void initState() {
    super.initState();
    _geminiService = GeminiService();
    _speechService = SpeechService();
    _ttsService = TTSService();
    _initServices();
  }

  Future<void> _initServices() async {
    print('🎬 [DriverHome] Initializing AI services...');
    await _speechService.initialize();
    await _ttsService.initialize();
    print('✅ [DriverHome] AI services ready');
  }

  void _toggleChat() {
    setState(() => _isChatOpen = !_isChatOpen);
    print('💬 [DriverHome] Chat ${_isChatOpen ? "opened" : "closed"}');
  }

  void _toggleTTS() {
    setState(() => _isTTSEnabled = !_isTTSEnabled);
    if (!_isTTSEnabled && _ttsService.isSpeaking) {
      _ttsService.stop();
    }
    _showSnackBar(
      _isTTSEnabled ? '🔊 Đã bật đọc tự động' : '🔇 Đã tắt đọc tự động',
      Colors.green,
    );
  }

  Future<void> _toggleMicrophone() async {
    if (_isListening) {
      await _speechService.stopListening();
      setState(() => _isListening = false);
    } else {
      if (!_speechService.isAvailable) {
        final initialized = await _speechService.initialize();
        if (!initialized) {
          _showSnackBar('❌ Không thể truy cập microphone', Colors.red);
          return;
        }
      }

      setState(() => _isListening = true);

      try {
        await _speechService.startListening(
          onResult: (text) {
            setState(() => _msgController.text = text);
          },
          localeId: 'vi-VN',
        );
      } catch (e) {
        setState(() => _isListening = false);
        _showSnackBar('❌ Lỗi nhận diện giọng nói', Colors.red);
      }
    }
  }

  Future<void> _sendMessage() async {
    if (_msgController.text.trim().isEmpty || _isLoading) return;

    if (_isListening) {
      await _speechService.stopListening();
      setState(() => _isListening = false);
    }

    if (_ttsService.isSpeaking) {
      await _ttsService.stop();
    }

    final userMessage = _msgController.text;
    _msgController.clear();

    setState(() {
      _messages.add(
        ChatMessage(
          text: userMessage,
          type: MessageType.user,
          time: DateTime.now(),
        ),
      );
      _messages.add(
        ChatMessage(
          text: '',
          type: MessageType.ai,
          time: DateTime.now(),
          isTyping: true,
        ),
      );
      _isLoading = true;
    });

    _scrollToBottom();

    try {
      final response = await _geminiService.sendMessage(
        userMessage,
        _getChatHistory(),
      );

      setState(() {
        _messages.removeLast();
        _messages.add(
          ChatMessage(
            text: response,
            type: MessageType.ai,
            time: DateTime.now(),
          ),
        );
        _isLoading = false;
      });

      _scrollToBottom();

      if (_isTTSEnabled) {
        await _ttsService.speak(response);
      }
    } catch (e) {
      setState(() {
        _messages.removeLast();
        _messages.add(
          ChatMessage(
            text: '❌ Lỗi: ${e.toString()}',
            type: MessageType.error,
            time: DateTime.now(),
          ),
        );
        _isLoading = false;
      });
      _scrollToBottom();
    }
  }

  List<Map<String, String>> _getChatHistory() {
    return _messages
        .where((m) => !m.isTyping && !m.isError)
        .map(
          (m) => {'role': m.isUser ? 'user' : 'assistant', 'content': m.text},
        )
        .toList();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients && mounted) {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      }
    });
  }

  void _showSnackBar(String message, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;

    return ChangeNotifierProvider(
      create: (_) => RouteProvider(),
      child: Scaffold(
        body: Stack(
          children: [
            // Main content
            IndexedStack(index: _currentIndex, children: _screens),

            // ==================== AI CHATBOX (DRAGGABLE) ====================
            Positioned(
              right: _chatPositionX,
              bottom: _chatPositionY,
              child: Draggable(
                feedback: Material(
                  color: Colors.transparent,
                  child: Opacity(opacity: 0.7, child: _buildChatStack()),
                ),
                childWhenDragging: Opacity(
                  opacity: 0.3,
                  child: _buildChatButton(),
                ),
                onDragEnd: (details) {
                  setState(() {
                    _chatPositionX = (screenSize.width - details.offset.dx - 56)
                        .clamp(0.0, screenSize.width - 56);
                    _chatPositionY =
                        (screenSize.height - details.offset.dy - 150).clamp(
                          0.0,
                          screenSize.height - 200,
                        );
                  });
                },
                child: _buildChatStack(),
              ),
            ),
          ],
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _currentIndex,
          onDestinationSelected: (index) {
            setState(() => _currentIndex = index);
          },
          backgroundColor: Colors.white,
          indicatorColor: AppColors.driverPrimary.withOpacity(0.2),
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.list_alt_outlined),
              selectedIcon: Icon(Icons.list_alt),
              label: 'Đơn hàng',
            ),
            NavigationDestination(
              icon: Icon(Icons.map_outlined),
              selectedIcon: Icon(Icons.map),
              label: 'Bản đồ',
            ),
            NavigationDestination(
              icon: Icon(Icons.account_circle_outlined),
              selectedIcon: Icon(Icons.account_circle),
              label: 'Tài khoản',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChatStack() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (_isChatOpen) _buildChatWindow(),
        const SizedBox(height: 10),
        _buildChatButton(),
      ],
    );
  }

  Widget _buildChatButton() {
    return FloatingActionButton(
      onPressed: _toggleChat,
      backgroundColor: AppColors.driverPrimary,
      child: Icon(_isChatOpen ? Icons.close : Icons.chat, color: Colors.white),
    );
  }

  Widget _buildChatWindow() {
    return Container(
      width: 350,
      height: 500,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 15,
            spreadRadius: 3,
          ),
        ],
      ),
      child: Column(
        children: [_buildChatHeader(), _buildChatMessages(), _buildChatInput()],
      ),
    );
  }

  Widget _buildChatHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.driverPrimary,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            backgroundColor: Colors.white,
            child: Icon(Icons.smart_toy, color: AppColors.driverPrimary),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'AI Assistant',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          IconButton(
            icon: Icon(
              _isTTSEnabled ? Icons.volume_up : Icons.volume_off,
              color: Colors.white,
            ),
            onPressed: _toggleTTS,
            tooltip: _isTTSEnabled ? 'Tắt đọc' : 'Bật đọc',
          ),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white),
            onPressed: _toggleChat,
          ),
        ],
      ),
    );
  }

  Widget _buildChatMessages() {
    return Expanded(
      child: _messages.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.chat_bubble_outline,
                    size: 64,
                    color: Colors.grey[300],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Bắt đầu trò chuyện với AI',
                    style: TextStyle(color: Colors.grey[400], fontSize: 16),
                  ),
                ],
              ),
            )
          : ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                return _buildMessageBubble(msg);
              },
            ),
    );
  }

  Widget _buildMessageBubble(ChatMessage msg) {
    if (msg.isTyping) {
      return Align(
        alignment: Alignment.centerLeft,
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(18),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 12,
                height: 12,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'AI đang trả lời...',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      );
    }

    return Align(
      alignment: msg.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        constraints: const BoxConstraints(maxWidth: 260),
        decoration: BoxDecoration(
          color: msg.isUser
              ? AppColors.driverPrimary
              : msg.isError
              ? Colors.red.withOpacity(0.1)
              : Colors.grey[200],
          borderRadius: BorderRadius.circular(18),
        ),
        child: Text(
          msg.text,
          style: TextStyle(
            color: msg.isUser
                ? Colors.white
                : msg.isError
                ? Colors.red
                : Colors.black87,
          ),
        ),
      ),
    );
  }

  Widget _buildChatInput() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(16),
          bottomRight: Radius.circular(16),
        ),
      ),
      child: Row(
        children: [
          // Microphone button
          Container(
            decoration: BoxDecoration(
              color: _isListening ? Colors.red : AppColors.driverPrimary,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: Icon(
                _isListening ? Icons.mic : Icons.mic_none,
                color: Colors.white,
              ),
              onPressed: _isLoading ? null : _toggleMicrophone,
              tooltip: _isListening ? 'Dừng ghi âm' : 'Nhấn để nói',
            ),
          ),
          const SizedBox(width: 8),

          // Text input
          Expanded(
            child: TextField(
              controller: _msgController,
              enabled: !_isLoading && !_isListening,
              decoration: InputDecoration(
                hintText: _isListening ? 'Đang nghe...' : 'Nhập tin nhắn...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
              ),
              onSubmitted: (_isLoading || _isListening)
                  ? null
                  : (_) => _sendMessage(),
            ),
          ),
          const SizedBox(width: 8),

          // Send button
          FloatingActionButton(
            mini: true,
            onPressed: (_isLoading || _isListening) ? null : _sendMessage,
            backgroundColor: AppColors.driverPrimary,
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.send, color: Colors.white),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _msgController.dispose();
    _scrollController.dispose();
    _speechService.dispose();
    _ttsService.dispose();
    super.dispose();
  }
}
