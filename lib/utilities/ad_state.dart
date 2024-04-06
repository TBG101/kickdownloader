import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdState {
  Future<InitializationStatus> initialization;
  bool loaded = false;
  bool loadedBannerAd = false;
  InterstitialAd? myAd;
  BannerAd? myBanner;

  AdState(this.initialization);

  String get bannerAdUnitId => "ca-app-pub-3940256099942544/6300978111";
  String get interstitialAdUnitId => "ca-app-pub-3940256099942544/8691691433";

  // adaptive banner
  void loadBannerAd() {
    initialization.then((value) {
      if (myBanner != null) myBanner!.dispose();
      myBanner = BannerAd(
          size: AdSize.fullBanner,
          adUnitId: bannerAdUnitId,
          listener: BannerAdListener(
            onAdLoaded: (ad) {
              loadedBannerAd = true;
              print("loaded");
            },
            onAdFailedToLoad: (ad, error) {
              loadedBannerAd = false;
              ad.dispose();
            },
          ),
          request: const AdRequest())
        ..load();
    });
  }

  // interstitual
  void loadInterAd() {
    initialization.then((value) {
      InterstitialAd.load(
          adUnitId: interstitialAdUnitId,
          request: const AdRequest(),
          adLoadCallback: InterstitialAdLoadCallback(
            onAdLoaded: (ad) {
              ad.fullScreenContentCallback = FullScreenContentCallback(
                onAdDismissedFullScreenContent: (ad) {
                  ad.dispose();
                  loadInterAd();
                },
              );
              loaded = true;
              print("loaded ad");
              myAd = ad;
            },
            onAdFailedToLoad: (error) {
              loaded = false;
              myAd = null;
            },
          ));
    });
  }

  void showInterAd() async {
    if (myAd == null) return;
    initialization.then((value) async => await myAd!.show());
  }
}
