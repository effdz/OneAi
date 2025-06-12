import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:oneai/models/chatbot_model.dart';
import 'package:oneai/screens/chat_screen.dart';
import 'package:oneai/services/chatbot_service.dart';
import 'package:oneai/utils/responsive.dart';
import 'package:oneai/utils/platform_adaptive.dart';
import 'package:provider/provider.dart';
import 'package:oneai/widgets/app_drawer.dart';
import 'package:oneai/main.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final chatbots = ChatbotService.getChatbots();
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isApple = PlatformAdaptive.isApplePlatform();

    // Responsive values
    final isDesktop = Responsive.isDesktop(context);
    final isTablet = Responsive.isTablet(context);
    final padding = Responsive.responsivePadding(context);
    final titleSize = Responsive.responsiveFontSize(
        context,
        mobile: 24,
        tablet: 28,
        desktop: 32
    );
    final subtitleSize = Responsive.responsiveFontSize(
        context,
        mobile: 16,
        tablet: 18,
        desktop: 20
    );

    // Grid columns based on screen size
    final crossAxisCount = isDesktop ? 4 : (isTablet ? 3 : 2);

    // Platform-specific app bar
    final appBar = PlatformAdaptive.appBar(
      context: context,
      title: 'OneAI Chatbot Hub',
      actions: [
        IconButton(
          icon: Icon(
            themeProvider.isDarkMode
                ? (isApple ? CupertinoIcons.sun_max : Icons.light_mode)
                : (isApple ? CupertinoIcons.moon : Icons.dark_mode),
          ),
          onPressed: themeProvider.toggleTheme,
          tooltip: themeProvider.isDarkMode ? 'Switch to Light Mode' : 'Switch to Dark Mode',
        ),
        IconButton(
          icon: Icon(isApple ? CupertinoIcons.settings : Icons.settings),
          onPressed: () {
            Navigator.pushNamed(context, '/settings');
          },
          tooltip: 'Settings',
        ),
      ],
    );

    return Scaffold(
      appBar: appBar,
      drawer: const AppDrawer(),
      body: SafeArea(
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          child: Padding(
            padding: padding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Choose an AI Assistant',
                  style: TextStyle(
                    fontSize: titleSize,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).textTheme.displaySmall?.color,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Select from multiple AI chatbots to start a conversation',
                  style: TextStyle(
                    fontSize: subtitleSize,
                    color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
                  ),
                ),
                const SizedBox(height: 24),
                Expanded(
                  child: GridView.builder(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: crossAxisCount,
                      childAspectRatio: 0.8,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                    ),
                    itemCount: chatbots.length,
                    itemBuilder: (context, index) {
                      final chatbot = chatbots[index];
                      return _ChatbotCard(chatbot: chatbot);
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ChatbotCard extends StatelessWidget {
  final ChatbotModel chatbot;

  const _ChatbotCard({required this.chatbot});

  @override
  Widget build(BuildContext context) {
    final isApple = PlatformAdaptive.isApplePlatform();

    return Hero(
      tag: 'chatbot-${chatbot.id}',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ChatScreen(chatbot: chatbot),
              ),
            );
          },
          borderRadius: BorderRadius.circular(16),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: chatbot.color.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(
                  color: chatbot.color.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: chatbot.color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(40),
                      ),
                      child: Icon(
                        isApple ? _getAppleIcon(chatbot.id) : chatbot.icon,
                        size: 40,
                        color: chatbot.color,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      chatbot.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      chatbot.description,
                      style: TextStyle(
                        fontSize: 14,
                        color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  IconData _getAppleIcon(String chatbotId) {
    switch (chatbotId) {
      case 'openai':
        return CupertinoIcons.sparkles;
      case 'gemini':
        return CupertinoIcons.globe;
      case 'huggingface':
        return CupertinoIcons.square_stack_3d_down_right;
      case 'mistral':
        return CupertinoIcons.wind;
      default:
        return CupertinoIcons.chat_bubble_2;
    }
  }
}
