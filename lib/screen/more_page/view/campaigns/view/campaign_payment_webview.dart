import 'package:hyper_local_seller/extensions/translation_extension.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:hyper_local_seller/widgets/custom/custom_scaffold.dart';
import 'package:hyper_local_seller/widgets/custom/custom_snackbar.dart';

import '../bloc/campaign_wallet_bloc/campaign_wallet_bloc.dart';

class CampaignPaymentWebView extends StatefulWidget {
  final String url;

  const CampaignPaymentWebView({super.key, required this.url});

  @override
  State<CampaignPaymentWebView> createState() => _CampaignPaymentWebViewState();
}

class _CampaignPaymentWebViewState extends State<CampaignPaymentWebView> {
  double _progress = 0;
  InAppWebViewController? _webViewController;
  late final CampaignWalletBloc _campaignWalletBloc;

  @override
  void initState() {
    super.initState();
    _campaignWalletBloc = context.read<CampaignWalletBloc>();
    // Start polling for balance change
    _campaignWalletBloc.add(StartTopupPolling());
  }

  @override
  void dispose() {
    // Stop polling when leaving
    _campaignWalletBloc.add(StopTopupPolling());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context;

    return BlocListener<CampaignWalletBloc, CampaignWalletState>(
      listener: (context, state) {
        if (state.topupStatus == TopupStatus.success) {
          showCustomSnackbar(
            context: context,
            message: state.topupMessage ?? 'Top up successful',
          );
          Navigator.pop(context);
        } else if (state.topupStatus == TopupStatus.failure) {
          showCustomSnackbar(
            context: context,
            message: state.error ?? 'Top up failed',
            isWarning: true,
          );
        }
      },
      child: CustomScaffold(
        title: l10n?.tr('payment') ?? 'Payment',
        showAppbar: true,
        centerTitle: true,
        appBarActions: [
          IconButton(
            onPressed: () {
              _webViewController?.reload();
            },
            icon: const Icon(Icons.refresh),
          ),
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close),
          ),
        ],
        body: Stack(
          children: [
            InAppWebView(
              initialUrlRequest: URLRequest(url: WebUri(widget.url)),
              initialSettings: InAppWebViewSettings(
                javaScriptEnabled: true,
                useShouldOverrideUrlLoading: true,
                supportMultipleWindows: true,
                javaScriptCanOpenWindowsAutomatically: true,
              ),
              onWebViewCreated: (controller) {
                _webViewController = controller;
              },
              onProgressChanged: (controller, progress) {
                setState(() {
                  _progress = progress / 100;
                });
              },
              onCreateWindow: (controller, createWindowAction) async {
                // Handle 3D Secure and other payment popups
                showGeneralDialog(
                  context: context,
                  barrierDismissible: false,
                  barrierLabel: "Payment Authentication",
                  pageBuilder: (context, animation, secondaryAnimation) {
                    return SafeArea(
                      child: Scaffold(
                        appBar: AppBar(
                          title: Text(context.tr('paymentAuthentication')),
                          leading: IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () => Navigator.pop(context),
                          ),
                          elevation: 0,
                        ),
                        body: InAppWebView(
                          windowId: createWindowAction.windowId,
                          onCloseWindow: (controller) {
                            Navigator.pop(context);
                          },
                        ),
                      ),
                    );
                  },
                );
                return true;
              },
              shouldOverrideUrlLoading: (controller, navigationAction) async {
                return NavigationActionPolicy.ALLOW;
              },
              onLoadStop: (controller, url) async {
                debugPrint("CampaignPayment onLoadStop: $url");
              },
            ),
            if (_progress < 1.0)
              LinearProgressIndicator(
                value: _progress,
                color: Theme.of(context).primaryColor,
                backgroundColor: Colors.transparent,
              ),
          ],
        ),
      ),
    );
  }
}
