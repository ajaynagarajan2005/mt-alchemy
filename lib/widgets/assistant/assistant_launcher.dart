import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../assistant/assistant_engine.dart' hide Intent;
import '../../assistant/knowledge.dart';
import '../../assistant/rag_client.dart';
import '../../data/models/people.dart';
import '../../router/routes.dart';
import '../../state/auth_store.dart';
import '../../state/cart_store.dart';
import '../../state/catalog_store.dart';
import '../../state/chat_store.dart';
import '../../state/commerce_store.dart';
import '../../state/learning_store.dart';
import '../../theme/colors.dart';
import '../../theme/radii.dart';
import '../../theme/spacing.dart';
import '../../theme/typography.dart';
import '../common/app_icon.dart';
import 'reply_blocks.dart';

/// The floating "Ask" button and the chat panel it opens. Sits above every
/// page. Answers come from the signed-in user's own records and from the
/// course material, and are drawn as charts, bars and cards.
class AssistantLauncher extends StatefulWidget {
  const AssistantLauncher({super.key, required this.router});

  final GoRouter router;

  @override
  State<AssistantLauncher> createState() => _AssistantLauncherState();
}

class _AssistantLauncherState extends State<AssistantLauncher> {
  bool _open = false;
  final _input = TextEditingController();
  final _scroll = ScrollController();
  final _focus = FocusNode();
  final _rag = RagClient();
  KnowledgeBase? _kb;
  int _kbCourses = -1;
  bool _loading = false;

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_onKey);
    if (_inserted) _entry.remove();
    _entry.dispose();
    _input.dispose();
    _scroll.dispose();
    _focus.dispose();
    super.dispose();
  }

  /// Changes this state and redraws the chat layer, which lives in the
  /// navigator's overlay rather than under this widget.
  void _update(VoidCallback change) {
    if (!mounted) return;
    setState(change);
    if (_inserted) _entry.markNeedsBuild();
  }

  /// Escape closes the chat wherever the keyboard focus is.
  bool _onKey(KeyEvent event) {
    if (_open &&
        event is KeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.escape) {
      _setOpen(false);
      return true;
    }
    return false;
  }

  @override
  void initState() {
    super.initState();
    HardwareKeyboard.instance.addHandler(_onKey);
  }

  void _setOpen(bool open) {
    _update(() => _open = open);
    if (open) {
      // Put the cursor in the question box so the user can type straight away.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _open) _focus.requestFocus();
      });
    } else {
      _focus.unfocus();
    }
  }

  Future<KnowledgeBase> _knowledge(CatalogStore catalog) async {
    final courses = catalog.allCourses;
    if (_kb == null || _kbCourses != courses.length) {
      _kbCourses = courses.length;
      _kb = await KnowledgeBase.load(courses);
    }
    return _kb!;
  }

  Future<void> _ask(String query) async {
    final q = query.trim();
    if (q.isEmpty || _loading) return;
    _input.clear();
    _update(() => _loading = true);
    final auth = context.read<AuthStore>();
    final catalog = context.read<CatalogStore>();
    final learning = context.read<LearningStore>();
    final commerce = context.read<CommerceStore>();
    final chat = context.read<ChatStore>();
    final products = catalog.products;
    final articles = catalog.articles;
    final kb = await _knowledge(catalog);
    final user = auth.currentUser;
    final ctx = AssistantContext(
      user: user,
      courses: user != null && user.role.isStaff
          ? catalog.allCourses
          : catalog.courses,
      enrolments: {for (final e in learning.enrolments) e.courseId: e},
      certificates: learning.certificates,
      orders: commerce.orders,
      assigned: learning.assigned,
      knowledge: kb,
      products: products,
      articles: articles,
    );
    var reply = const AssistantEngine().answer(q, ctx);
    // Questions about course content go to the retrieval service (LangChain
    // and a Chroma vector database). If it is off or unreachable, the answer
    // from the built-in keyword search stays.
    if (reply.intent == 'doubt') {
      final token = await auth.idToken();
      final rag = await _rag.ask(q, idToken: token, snapshot: snapshotOf(ctx));
      if (rag != null && rag.answer.isNotEmpty) {
        reply = AssistantReply('doubt', [RagAnswerBlock(rag)]);
      }
    }
    await chat.ask(q, reply);
    if (!mounted) return;
    _update(() => _loading = false);
    if (_open) _focus.requestFocus();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _go(String path) {
    widget.router.go(path);
    // On phones the panel covers the page, so close it after navigating.
    if (MediaQuery.sizeOf(context).width < 600) _setOpen(false);
  }

  void _buy(CourseSuggestion s) {
    final cart = context.read<CartStore>();
    if (!context.read<AuthStore>().isSignedIn) {
      widget.router.go(
        Uri(
          path: Routes.login,
          queryParameters: {'from': Routes.course(s.course.id)},
        ).toString(),
      );
      _setOpen(false);
      return;
    }
    if (!cart.containsCourse(s.course.id)) cart.addCourse(s.course);
    widget.router.go(Routes.checkout);
    _setOpen(false);
  }

  // The chat layer is an entry in the app navigator's own Overlay, so it sits
  // above every page and gets the Overlay that tooltips and text fields need.
  // (A separate Overlay stacked beside the Navigator was queried by the focus
  // system before it was laid out, which threw and broke keyboard focus.)
  late final OverlayEntry _entry = OverlayEntry(builder: _content);
  bool _inserted = false;

  void _attach() {
    if (!mounted || _inserted) return;
    final overlay =
        widget.router.routerDelegate.navigatorKey.currentState?.overlay;
    if (overlay == null) {
      // The navigator is not built yet; try again after the next frame.
      WidgetsBinding.instance.addPostFrameCallback((_) => _attach());
      return;
    }
    overlay.insert(_entry);
    _inserted = true;
  }

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) => _attach());
    return const SizedBox.shrink();
  }

  Widget _content(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final phone = size.width < 600;
    final panelW = phone ? size.width - 16 : 420.0;
    final panelH = phone
        ? size.height - 24
        : (size.height - 120).clamp(360.0, 640.0);

    // Only the button or the panel takes taps, so the page underneath stays
    // usable.
    return Positioned(
      right: phone ? 8 : 20,
      bottom: phone ? 12 : 20,
      child: Material(
        type: MaterialType.transparency,
        child: _open
            ? SizedBox(
                width: panelW,
                height: panelH,
                // Escape inside the chat (a "dismiss") closes it.
                child: Actions(
                  actions: {
                    DismissIntent: CallbackAction<DismissIntent>(
                      onInvoke: (_) {
                        _setOpen(false);
                        return null;
                      },
                    ),
                  },
                  child: _Panel(
                    input: _input,
                    scroll: _scroll,
                    focus: _focus,
                    loading: _loading,
                    onAsk: _ask,
                    onClose: () => _setOpen(false),
                    actions: BlockActions(ask: _ask, go: _go, buy: _buy),
                  ),
                ),
              )
            : _LaunchButton(onTap: () => _setOpen(true)),
      ),
    );
  }
}

class _LaunchButton extends StatelessWidget {
  const _LaunchButton({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Ask the MT Alchemy assistant',
      child: Material(
        color: AppColors.accentFill,
        elevation: 6,
        shadowColor: AppColors.shadowTint,
        // A light edge keeps the button visible on the dark footer band.
        shape: const StadiumBorder(
          side: BorderSide(color: Color(0x80FFFFFF), width: 1.5),
        ),
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                AppIcon(
                  HugeIcons.strokeRoundedBubbleChat,
                  size: 22,
                  color: AppColors.onAccent,
                ),
                const SizedBox(width: 8),
                Text(
                  'Ask',
                  style: AppText.label.copyWith(color: AppColors.onAccent),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Panel extends StatelessWidget {
  const _Panel({
    required this.input,
    required this.scroll,
    required this.focus,
    required this.loading,
    required this.onAsk,
    required this.onClose,
    required this.actions,
  });

  final TextEditingController input;
  final ScrollController scroll;
  final FocusNode focus;
  final bool loading;
  final void Function(String) onAsk;
  final VoidCallback onClose;
  final BlockActions actions;

  @override
  Widget build(BuildContext context) {
    final chat = context.watch<ChatStore>();
    final signedIn = context.watch<AuthStore>().isSignedIn;
    final entries = chat.entries;
    return Material(
      color: AppColors.surface,
      elevation: 12,
      shadowColor: AppColors.shadowTint,
      borderRadius: Radii.cardAll,
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.fromLTRB(
              Space.md,
              Space.sm,
              Space.xs,
              Space.sm,
            ),
            decoration: BoxDecoration(gradient: AppColors.transformation),
            child: Row(
              children: [
                AppIcon(
                  HugeIcons.strokeRoundedBubbleChat,
                  size: 22,
                  color: AppColors.onInverse,
                ),
                const SizedBox(width: Space.xs),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Ask MT Alchemy',
                        style: AppText.label.copyWith(
                          color: AppColors.onInverse,
                        ),
                      ),
                      Text(
                        signedIn
                            ? 'Uses your courses, payments and the course notes'
                            : 'Sign in to include your own records',
                        style: AppText.small.copyWith(
                          color: AppColors.inverseMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                if (entries.isNotEmpty)
                  IconButton(
                    tooltip: 'Clear the conversation',
                    onPressed: chat.clearConversation,
                    icon: Icon(
                      Icons.delete_sweep_outlined,
                      color: AppColors.onInverse,
                    ),
                  ),
                IconButton(
                  tooltip: 'Close',
                  onPressed: onClose,
                  icon: Icon(Icons.close, color: AppColors.onInverse),
                ),
              ],
            ),
          ),
          // Conversation
          Expanded(
            child: ListView(
              controller: scroll,
              padding: const EdgeInsets.all(Space.md),
              children: [
                if (entries.isEmpty) ...[
                  Text(
                    'Ask about your progress, your payments, courses you can add, or anything taught in the courses.',
                    style: AppText.body,
                  ),
                  const SizedBox(height: Space.sm),
                  ReplyBlockView(
                    block: const SuggestionsBlock(AssistantEngine.suggestions),
                    actions: actions,
                  ),
                  if (chat.recent.isNotEmpty) ...[
                    const SizedBox(height: Space.md),
                    Text('Your recent questions', style: AppText.small),
                    const SizedBox(height: Space.xs),
                    ReplyBlockView(
                      block: SuggestionsBlock(chat.recent),
                      actions: actions,
                    ),
                  ],
                ],
                for (final e in entries) ...[
                  if (e.fromUser)
                    Align(
                      alignment: Alignment.centerRight,
                      child: Container(
                        margin: const EdgeInsets.only(
                          left: 48,
                          bottom: Space.sm,
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: Space.md,
                          vertical: Space.sm,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.accentFill,
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(18),
                            topRight: Radius.circular(18),
                            bottomLeft: Radius.circular(18),
                            bottomRight: Radius.circular(4),
                          ),
                        ),
                        child: Text(
                          e.text!,
                          style: AppText.body.copyWith(
                            color: AppColors.onAccent,
                          ),
                        ),
                      ),
                    )
                  else
                    Padding(
                      padding: const EdgeInsets.only(bottom: Space.md),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          for (final b in e.reply!.blocks) ...[
                            ReplyBlockView(block: b, actions: actions),
                            const SizedBox(height: Space.sm),
                          ],
                        ],
                      ),
                    ),
                ],
                if (loading)
                  const Padding(
                    padding: EdgeInsets.all(Space.sm),
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
              ],
            ),
          ),
          // Input
          Container(
            padding: const EdgeInsets.fromLTRB(
              Space.sm,
              Space.xs,
              Space.sm,
              Space.sm,
            ),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: AppColors.line)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: input,
                    focusNode: focus,
                    autofocus: true,
                    textInputAction: TextInputAction.send,
                    onSubmitted: onAsk,
                    // Keep the cursor in the box after sending, so the next
                    // question can be typed straight away.
                    onEditingComplete: () {},
                    style: AppText.body,
                    decoration: InputDecoration(
                      hintText: 'Type your question',
                      hintStyle: AppText.bodyMuted,
                      isDense: true,
                      filled: true,
                      fillColor: AppColors.grey50,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: Radii.pillAll,
                        borderSide: BorderSide(color: AppColors.line),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: Radii.pillAll,
                        borderSide: BorderSide(color: AppColors.line),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: Radii.pillAll,
                        borderSide: BorderSide(color: AppColors.red, width: 2),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: Space.xs),
                IconButton.filled(
                  tooltip: 'Send',
                  style: IconButton.styleFrom(
                    backgroundColor: AppColors.accentFill,
                    minimumSize: const Size(46, 46),
                  ),
                  onPressed: () => onAsk(input.text),
                  icon: Icon(
                    Icons.send_rounded,
                    size: 20,
                    color: AppColors.onAccent,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
