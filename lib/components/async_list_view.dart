import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shma_server/components/horizontal_spacer.dart';
import 'package:shma_server/components/progress_indicator.dart';
import 'package:shma_server/models/channel_config.dart';
import 'package:flutter_gen/gen_l10n/shma_server_localizations.dart';
import 'package:shma_server/services/router.dart';

/// Function to load data with the passed [filter], starting from [offset] and
/// loading an amount of [take] data. Also a [subfilter] can be added to filter the list more specific.
typedef LoadDataFunction = Future<List<ChannelConfig>> Function();

/// Function that is called when an action is performed on selected items the items with the passed [itemIdentifiers].
///
/// This function should return a [Future], that either resolves with true
/// after successful action or false on cancel.
/// The list will reload the data starting from beginning, if true will be
/// returned.
typedef ActionPerfomedFunction = Future<bool> Function<T>(
    List<T> itemIdentifiers);

/// Function that is called when an action is performed on selected items the items with the passed [itemIdentifiers].
///
/// This function should return a [Future], that either resolves with true
/// after successful action or false on cancel.
/// The list will reload the data starting from beginning, if true will be
/// returned.
typedef EventActionPerfomedFunction = Future<void> Function();

/// Function that updates the passed [item].
///
/// This function should return a [Future], that either resolves with true
/// after successful update or false on cancel.
/// The list will reload the data starting from beginning, if true will be
/// returned.
typedef EditFunction = Future<bool> Function(ChannelConfig item);

/// Function that creates an new item.
///
/// This function should return a [Future], that either resolves with true
/// after successful creation or false on cancel.
/// The list will reload the data starting from beginning, if true will be
/// returned.
typedef AddFunction = Future<bool> Function();

/// List that supports async loading of data, when necessary in chunks.
class AsyncListView extends StatefulWidget {
  /// Function to load data with the passed [filter], starting from [offset] and
  /// loading an amount of [take] data.
  final LoadDataFunction loadData;

  /// Function that deletes the items with the passed [itemIdentifiers].
  ///
  /// This function should return a [Future], that either resolves with true
  /// after successful deletion or false on cancel.
  /// The list will reload the data starting from beginning, if true will be
  /// returned.
  final ActionPerfomedFunction deleteItems;

  /// Called, when configuration button is pressed.
  final EventActionPerfomedFunction openConfiguration;

  /// Function that creates an new item.
  ///
  /// This function should return a [Future], that either resolves with true
  /// after successful creation or false on cancel.
  /// The list will reload the data starting from beginning, if true will be
  /// returned.
  final AddFunction addItem;

  /// Function that updates the passed [item].
  ///
  /// This function should return a [Future], that either resolves with true
  /// after successful update or false on cancel.
  /// The list will reload the data starting from beginning, if true will be
  /// returned.
  final EditFunction editItem;

  final EditFunction onStream;

  /// Initializes the list view.
  const AsyncListView({
    Key? key,
    required this.loadData,
    required this.deleteItems,
    required this.editItem,
    required this.openConfiguration,
    required this.addItem,
    required this.onStream,
  }) : super(key: key);

  @override
  State<AsyncListView> createState() => _AsyncListViewState();
}

/// State of the list view.
class _AsyncListViewState extends State<AsyncListView> {
  /// Indicates, whether the list is currently in multi select mode.
  bool _isEditMode = false;

  /// Identifiers of the selected items in the list.
  List<dynamic> _selectedItems = [];

  /// List of lazy loaded items.
  List<ChannelConfig>? _items;

  /// Indicates, whether data is loading and an loading indicator should be
  /// shown.
  bool _isLoadingData = true;

  @override
  void initState() {
    _reloadData();
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RawKeyboardListener(
      autofocus: true,
      focusNode: FocusNode(),
      onKey: (event) => {
        if (event.isKeyPressed(LogicalKeyboardKey.f5)) {_reloadData()}
      },
      child: Scaffold(
        body: Column(
          children: [
            // List header with filter and action buttons.
            _createListHeaderWidget(),

            // List, loading indicator or no data widget.
            Expanded(
              child: _isLoadingData
                  ? _createLoadingWidget()
                  : (_items!.isNotEmpty
                      ? _createListViewWidget()
                      : _createNoDataWidget()),
            ),
          ],
        ),

        // Floating button.
        floatingActionButton: _createActionButton(),
      ),
    );
  }

  /// Stores the identifer of the item at the [index] or removes it, when
  /// the identifier was in the list of selected items.
  void _onItemChecked(int index) {
    if (_selectedItems.any((item) => item.id == _items![index].id)) {
      _selectedItems.remove(_items![index]);
    } else {
      _selectedItems.add(_items![index]);
    }

    setState(() {
      _selectedItems = _selectedItems;
    });
  }

  /// Reloads the data starting from inital offset with inital count.
  void _reloadData() {
    if (!mounted) {
      return;
    }

    _loadData();
  }

  /// Loads the data for the [_offset] and [_take] with the [_filter].
  ///
  /// Shows a loading indicator instead of the list during load, if
  /// [showLoadingOverlay] is true.
  /// Otherwhise the data will be loaded lazy in the background.
  void _loadData({
    bool showLoadingOverlay = true,
  }) {
    if (showLoadingOverlay) {
      setState(() {
        _isLoadingData = true;
      });
    }

    var dataFuture = widget.loadData();

    dataFuture.then((value) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isLoadingData = false;
        _items = value;
      });
    }).onError((e, _) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isLoadingData = false;
        _items = [];
      });
    });
  }

  /// Show a floating action button or an expanding fab.
  ///
  /// When no sub action buttons given, only the add action button is shown, when [widget.showAddButton] is true.
  /// When a list of sub action buttons is provided, an expandable action button will be shown.
  Widget _createActionButton() {
    return FloatingActionButton(
      onPressed: () {
        widget.addItem().then((value) {
          if (value) {
            _reloadData();
          }
        });
      },
      tooltip: AppLocalizations.of(context)!.add,
      child: const Icon(Icons.add),
    );
  }

  /// Creates the list header widget with filter and remove action buttons.
  Widget _createListHeaderWidget() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 20),
      child: Row(
        mainAxisSize: MainAxisSize.max,
        children: [
          // Filter input.
          Visibility(
            visible: !_isEditMode,
            child: Expanded(
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      IconButton(
                        onPressed: () => _reloadData(),
                        icon: const Icon(Icons.refresh),
                      ),
                      IconButton(
                        onPressed: () => setState(() {
                          _isEditMode = !_isEditMode;
                        }),
                        icon: const Icon(Icons.edit),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Remove action buttons. Only visible in multi select mode.
          Visibility(
            visible: _isEditMode,
            child: Expanded(
              child: Container(
                padding: const EdgeInsets.only(top: 5, bottom: 5),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () {
                        setState(() {
                          _isEditMode = false;
                          _selectedItems = [];
                        });
                      },
                      icon: const Icon(Icons.close),
                      tooltip: AppLocalizations.of(context)!.cancel,
                    ),
                    horizontalSpacer,
                    Text("${_selectedItems.length}"),
                    const Spacer(),
                    IconButton(
                      onPressed: () {
                        for (var element in _items!) {
                          if (!_selectedItems.contains(element)) {
                            _selectedItems.add(element);
                          }
                        }

                        setState(() {
                          _selectedItems = _selectedItems;
                        });
                      },
                      icon: const Icon(Icons.check_box_outlined),
                      tooltip: AppLocalizations.of(context)!.selectLoaded,
                    ),
                    IconButton(
                      onPressed: () {
                        showProgressIndicator();
                        widget.deleteItems(_selectedItems).then((value) {
                          if (!mounted) {
                            return;
                          }

                          RouterService.getInstance()
                              .navigatorKey
                              .currentState!
                              .pop();

                          if (!value) {
                            return;
                          }

                          setState(() {
                            _isEditMode = false;
                            _selectedItems = [];
                          });

                          _reloadData();
                        }).onError((error, stackTrace) {
                          if (!mounted) {
                            return;
                          }

                          RouterService.getInstance()
                              .navigatorKey
                              .currentState!
                              .pop();
                        });
                      },
                      icon: const Icon(Icons.delete),
                      tooltip: AppLocalizations.of(context)!.remove,
                    ),
                  ],
                ),
              ),
            ),
          ),
          IconButton(
            onPressed: () => widget.openConfiguration().then(
                  (value) => _reloadData(),
                ),
            icon: const Icon(Icons.qr_code),
            tooltip: AppLocalizations.of(context)!.connectionConfig,
          ),
        ],
      ),
    );
  }

  /// Creates the list view widget.
  Widget _createListViewWidget() {
    return ScrollConfiguration(
      behavior: ScrollConfiguration.of(context).copyWith(
        scrollbars: false,
      ),
      child: ListView.separated(
        separatorBuilder: (context, index) {
          return const Divider(
            height: 1,
          );
        },
        itemBuilder: (context, index) {
          return _createListTile(index);
        },
        itemCount: _items?.length ?? 0,
      ),
    );
  }

  /// Creates a loading indicator widget.
  Widget _createLoadingWidget() {
    return const Center(
      child: CircularProgressIndicator(),
    );
  }

  /// Creates a widget that will be shown, if no data were loaded or an error
  /// occured during loading of data.
  Widget _createNoDataWidget() {
    return Center(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            AppLocalizations.of(context)!.noData,
            softWrap: true,
          ),
          horizontalSpacer,
          TextButton.icon(
            onPressed: () => _loadData(),
            icon: const Icon(Icons.refresh),
            label: Text(AppLocalizations.of(context)!.reload),
          ),
        ],
      ),
    );
  }

  /// Creates a tile widget for one list item at the given [index] or a group widget.
  Widget _createListTile(int index) {
    var item = _items![index];

    var leadingTile = !_isEditMode ? null : _selectCheckbox(index, item);

    return _listTile(leadingTile, item, index);
  }

  /// Creates a tile widget for one list [item] at the given [index].
  ListTile _listTile(Widget? leadingTile, ChannelConfig item, int index) {
    return ListTile(
      leading: leadingTile,
      minVerticalPadding: 5,
      visualDensity: const VisualDensity(vertical: 0),
      title: Wrap(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Text(
              item.title ?? "",
              overflow: TextOverflow.fade,
              maxLines: 1,
              softWrap: false,
            ),
          ),
        ],
      ),
      subtitle: Text(
        "${AppLocalizations.of(context)!.connectedClients}: ${item.activeClients}",
      ),
      trailing: IconButton(
        icon: item.isStreaming
            ? const Icon(Icons.stop)
            : const Icon(Icons.play_arrow),
        onPressed: () => widget.onStream(item),
      ),
      onTap: () {
        if (_isEditMode) {
          _onItemChecked(index);
        } else {
          widget.editItem(item).then((value) {
            if (value) {
              _reloadData();
            }
          });
        }
      },
      onLongPress: () {
        if (!_isEditMode) {
          setState(() {
            _isEditMode = true;
          });
        }

        _onItemChecked(index);
      },
    );
  }

  Widget _selectCheckbox(int index, ChannelConfig item) {
    return Checkbox(
      splashRadius: 0,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(
          Radius.circular(5.0),
        ),
      ),
      onChanged: (_) {
        _onItemChecked(index);
      },
      value: _selectedItems.any((elem) => elem.id == item.id),
    );
  }
}
