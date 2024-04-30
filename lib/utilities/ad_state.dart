import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdState {
  late final Future<InitializationStatus> initialization;

  AdState(this.initialization);

  bool loaded = false;
  InterstitialAd? myAd;

  BannerAd? myBanner;
  bool loadedBannerAd = false;

  AppOpenAd? myAppOpenAd;
  bool loadedMyAppOpenAd = false;
  bool clickedOnMyAppOpenAd = false;

  String get bannerAdUnitId => "ca-app-pub-3940256099942544/6300978111";
  String get interstitialAdUnitId => "ca-app-pub-3940256099942544/8691691433";
  String get appOpenAd => "ca-app-pub-3940256099942544/9257395921";
  int timeSinceLastAdShow = 0;

  // open app ad
  Future<void> showAppOpenAd() async {
    if (myAppOpenAd == null ||
        loadedMyAppOpenAd == false ||
        timeSinceLastAdShow == 0 ||
        DateTime.timestamp().millisecondsSinceEpoch >
            timeSinceLastAdShow + 180000) return;
    // shows only if time passed since last ad is greater than 3 mintes == 180000 ms

    myAppOpenAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        myAppOpenAd!.dispose();
        loadAppOpenAd();
      },
      onAdClicked: (ad) {
        clickedOnMyAppOpenAd = true;
        myAppOpenAd!.dispose();
        loadAppOpenAd();
      },
    );
    // Show ad
    myAppOpenAd!.show();
    // Save the last times
    timeSinceLastAdShow = DateTime.timestamp().millisecondsSinceEpoch;
  }

  Future<void> loadAppOpenAd() async {
    initialization.then((value) {
      AppOpenAd.load(
          adUnitId: appOpenAd,
          request: const AdRequest(),
          adLoadCallback: AppOpenAdLoadCallback(
            onAdLoaded: (ad) {
              myAppOpenAd = ad;
              loadedMyAppOpenAd = true;
            },
            onAdFailedToLoad: (error) {
              loadedMyAppOpenAd = false;
              myAppOpenAd = null;
            },
          ));
    });
  }

  // adaptive banner
  Future<void> loadBannerAd() async {
    initialization.then((value) async {
      if (myBanner != null) await myBanner!.dispose();

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
  Future<void> loadInterAd() async {
    initialization.then((value) {
      InterstitialAd.load(
          adUnitId: interstitialAdUnitId,
          request: const AdRequest(),
          adLoadCallback: InterstitialAdLoadCallback(
            onAdLoaded: (ad) {
              ad.fullScreenContentCallback = FullScreenContentCallback(
                onAdFailedToShowFullScreenContent: (ad, error) {
                  myAd!.dispose();
                  myAd = null;
                },
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

  Future<void> showInterAd() async {
    if (myAd == null || loaded == false) return;
    initialization.then((value) async => await myAd!.show());
  }
}
