import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shma_server/components/async_list_view.dart';
import 'package:shma_server/view_models/main.dart';

class MainScreen extends StatelessWidget {
  /// Initializes the instance.
  const MainScreen({Key? key}) : super(key: key);

  /// Builds the main screen with the navigator instance.
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ChangeNotifierProvider<MainViewModel>(
        create: (context) => MainViewModel(),
        builder: (context, _) {
          var vm = Provider.of<MainViewModel>(context, listen: false);
          return FutureBuilder(
            future: vm.init(context),
            builder: (BuildContext context, AsyncSnapshot<bool> snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              return SafeArea(
                child: Consumer<MainViewModel>(
                  builder: (context, vm, child) {
                    return AsyncListView(
                      addItem: () => vm.add(),
                      editItem: (item) => vm.edit(item),
                      deleteItems: <String>(List<String> itemIdentifiers) =>
                          vm.delete(itemIdentifiers),
                      loadData: () {
                        return vm.load();
                      },
                      openConfiguration: () => vm.manageConfiguration(),
                      onStream: (item) => vm.changeStreamState(item),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
