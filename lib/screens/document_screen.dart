import 'dart:async';

import 'package:docs/common/widgets/loader.dart';
import 'package:docs/models/document_model.dart';
import 'package:docs/models/error_model.dart';
import 'package:docs/repository/auth_repository.dart';
import 'package:docs/repository/document_repository.dart';
import 'package:docs/repository/socket_repository.dart';
import 'package:docs/utiils/colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:routemaster/routemaster.dart';

class DocumentScreen extends ConsumerStatefulWidget {
  final String id;

  const DocumentScreen({required this.id, Key? key}) : super(key: key);

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _DocumentScreenState();
}

class _DocumentScreenState extends ConsumerState<DocumentScreen> {
  TextEditingController titleContoller =
      TextEditingController(text: 'Untitled document');
  ErrorModel? errorModel;

  SocketRepository socketRepository = SocketRepository();
  quill.QuillController? _controller;

  @override
  void initState() {
    socketRepository.joinRoom(widget.id);
    fetchDocumentData();

    socketRepository.changeListener((data) {
      _controller?.compose(
          quill.Delta.fromJson(data['delta']),
          _controller?.selection ?? const TextSelection.collapsed(offset: 0),
          quill.ChangeSource.REMOTE);
    });
    Timer.periodic(const Duration(seconds: 2), (timer) {
      socketRepository.autoSave(<String, dynamic>{
        'delta': _controller!.document.toDelta(),
        'room': widget.id
      });
    });
  }

  @override
  void dispose() {
    titleContoller.dispose();
    super.dispose();
  }

  void fetchDocumentData() async {
    errorModel = await ref.read(documentRepositoryProvider).getDocument(
          ref.read(userProvider)!.token,
          widget.id,
        );
    if (errorModel!.data != null) {
      titleContoller.text = (errorModel!.data as DocumentModel).title;
      _controller = quill.QuillController(
        document: errorModel!.data.content.isEmpty
            ? quill.Document()
            : quill.Document.fromDelta(
                quill.Delta.fromJson(errorModel!.data.content)),
        selection: const TextSelection.collapsed(offset: 0),
      );
      setState(() {});
      _controller!.document.changes.listen(
        (event) {
          if (event.item3 == quill.ChangeSource.LOCAL) {
            Map<String, dynamic> map = {
              'delta': event.item2,
              'room': widget.id,
            };
            socketRepository.typing(map);
          }
        },
      );
    }
  }

  void updateTitle(WidgetRef ref, String title) {
    ref.read(documentRepositoryProvider).updateDocument(
          token: ref.read(userProvider)!.token,
          id: widget.id,
          title: title,
        );
  }

  @override
  Widget build(BuildContext context) {
    if (_controller == null) {
      return const Scaffold(
        body: Loader(),
      );
    }
    return Scaffold(
        appBar: AppBar(
            backgroundColor: whiteColor,
            actions: [
              Padding(
                padding: const EdgeInsets.all(10.0),
                child: ElevatedButton.icon(
                  onPressed: () {
                    Clipboard.setData(ClipboardData(
                            text:
                                'http://localhost:3000/#/document/${widget.id}'))
                        .then(
                      (value) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Link copied!',
                            ),
                          ),
                        );
                      },
                    );
                  },
                  icon: const Icon(
                    Icons.lock,
                    color: blackColor,
                    size: 16,
                  ),
                  label: const Text('Share'),
                  style: ElevatedButton.styleFrom(backgroundColor: blueColor),
                ),
              ),
            ],
            title: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () {
                      Routemaster.of(context).replace('/');
                    },
                    child: Image.asset(
                      'assets/images/docs-logo.png',
                      height: 40,
                    ),
                  ),
                  const SizedBox(
                    width: 10,
                  ),
                  SizedBox(
                    width: 180,
                    child: TextField(
                      onSubmitted: (value) => updateTitle(ref, value),
                      controller: titleContoller,
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                            color: blueColor,
                          ),
                        ),
                        contentPadding: EdgeInsets.only(left: 10),
                      ),
                    ),
                  )
                ],
              ),
            ),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(1),
              child: Container(
                  decoration: BoxDecoration(
                border: Border.all(color: greyColor, width: 0.1),
              )),
            )),
        body: Center(
          child: Column(
            children: [
              const SizedBox(
                height: 10,
              ),
              quill.QuillToolbar.basic(controller: _controller!),
              Expanded(
                child: SizedBox(
                  width: 750,
                  child: Card(
                    color: whiteColor,
                    elevation: 5,
                    child: Padding(
                      padding: const EdgeInsets.all(30.0),
                      child: quill.QuillEditor.basic(
                        controller: _controller!,
                        readOnly: false,
                      ),
                    ),
                  ),
                ),
              )
            ],
          ),
        ));
  }
}
