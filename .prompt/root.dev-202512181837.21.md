**Input:**

**Scope:** *None*

**Git Log:** *None*

**Diff:**
```diff
diff --git a/lib/ui/archives/widgets/archives_screen.dart b/lib/ui/archives/widgets/archives_screen.dart
index 9f8b9dd..4bba85a 100644
--- a/lib/ui/archives/widgets/archives_screen.dart
+++ b/lib/ui/archives/widgets/archives_screen.dart
@@ -1,3 +1,4 @@
+import 'package:fading_edge_scrollview/fading_edge_scrollview.dart';
 import 'package:flutter/material.dart';
 import 'package:go_router/go_router.dart';
 import 'package:too_many_tabs/routing/routes.dart';
@@ -18,6 +19,7 @@ class ArchivesScreen extends StatefulWidget {
 
 class _ArchivesScreenState extends State<ArchivesScreen> {
   late final AppLifecycleListener _listener;
+  final _controller = ScrollController();
 
   @override
   void initState() {
@@ -31,6 +33,7 @@ class _ArchivesScreenState extends State<ArchivesScreen> {
 
   @override
   void dispose() {
+    _controller.dispose();
     _listener.dispose();
     super.dispose();
   }
@@ -81,33 +84,43 @@ class _ArchivesScreenState extends State<ArchivesScreen> {
               child: ListenableBuilder(
                 listenable: widget.viewModel,
                 builder: (context, _) {
-                  return CustomScrollView(
-                    slivers: [
-                      SliverList.builder(
-                        itemCount: widget.viewModel.routines.length,
-                        itemBuilder: (_, index) {
-                          return Routine(
-                            index: index,
-                            key: ValueKey(widget.viewModel.routines[index].id),
-                            routine: widget.viewModel.routines[index],
-                            restore: () async {
-                              await widget.viewModel.restore.execute(
-                                widget.viewModel.routines[index].id,
+                  return FadingEdgeScrollView.fromScrollView(
+                    gradientFractionOnEnd: 0.8,
+                    gradientFractionOnStart: 0,
+                    child: CustomScrollView(
+                      controller: _controller,
+                      slivers: [
+                        SliverSafeArea(
+                          minimum: EdgeInsets.only(bottom: 120),
+                          sliver: SliverList.builder(
+                            itemCount: widget.viewModel.routines.length,
+                            itemBuilder: (_, index) {
+                              return Routine(
+                                index: index,
+                                key: ValueKey(
+                                  widget.viewModel.routines[index].id,
+                                ),
+                                routine: widget.viewModel.routines[index],
+                                restore: () async {
+                                  await widget.viewModel.restore.execute(
+                                    widget.viewModel.routines[index].id,
+                                  );
+                                  if (context.mounted) {
+                                    context.go(Routes.home);
+                                  }
+                                },
+                                trash: () async {
+                                  await widget.viewModel.bin.execute(
+                                    widget.viewModel.routines[index].id,
+                                  );
+                                  await widget.viewModel.load.execute();
+                                },
                               );
-                              if (context.mounted) {
-                                context.go(Routes.home);
-                              }
                             },
-                            trash: () async {
-                              await widget.viewModel.bin.execute(
-                                widget.viewModel.routines[index].id,
-                              );
-                              await widget.viewModel.load.execute();
-                            },
-                          );
-                        },
-                      ),
-                    ],
+                          ),
+                        ),
+                      ],
+                    ),
                   );
                 },
               ),


----------------

git status -s

M  lib/ui/archives/widgets/archives_screen.dart

```


-------------------------------------------------
-------- NEXT STEPS AND WORK IN PROGRESS --------
-------------------------------------------------


**WIP Context:**

*Implementation Todos:*
- bin screen customscrollview fading as in archives screen

