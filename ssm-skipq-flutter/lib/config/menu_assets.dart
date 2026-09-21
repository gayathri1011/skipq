import '../models/menu.dart';

/// Local menu thumbnails synced from ssm-skipq-frontend/src/assets/menu.
class MenuAssets {
  static const _byNormalizedName = {
    'vegetable biryani': 'assets/menu/veg-briyani.png',
    'mushroom biryani': 'assets/menu/mushroom-briyani.png',
    'chicken biryani': 'assets/menu/chicken-biriyani.png',
    'curd rice': 'assets/menu/curd-rice.png',
    'sambar rice': 'assets/menu/sambar-rice.png',
    'parotta 2 pieces': 'assets/menu/parotta.png',
    'parotta (2 pieces)': 'assets/menu/parotta.png',
    'kothu parotta': 'assets/menu/veg-kothu-parotta.png',
    'egg kothu parotta': 'assets/menu/egg-kothu-parotta.png',
    'chicken kothu parotta': 'assets/menu/chicken-kothu-porotta.png',
    'veg fried rice': 'assets/menu/veg-friedrice.png',
    'egg fried rice': 'assets/menu/egg-fried-rice.png',
    'chicken fried rice': 'assets/menu/chicken-fried-rice.png',
    'chapati 2 pieces': 'assets/menu/chapathi.png',
    'chapati (2 pieces)': 'assets/menu/chapathi.png',
    'chapathi 2 pieces': 'assets/menu/chapathi.png',
    'chapathi (2 pieces)': 'assets/menu/chapathi.png',
    'chicken 65': 'assets/menu/chicken65.png',
    'mushroom 65': 'assets/menu/mushroom65.png',
    'omelette': 'assets/menu/omblete.png',
    'chicken gravy': 'assets/menu/chicken-gravy.png',
    'paneer gravy': 'assets/menu/paneer-gravy.png',
    'egg puff': 'assets/menu/egg-puff.png',
    'paneer puff': 'assets/menu/panner-puff.png',
    'chicken puff': 'assets/menu/chicken-puff.png',
    'mushroom puff': 'assets/menu/mushroom-puff.png',
    'paruppu vadai': 'assets/menu/parupu-vadai.png',
    'ulundhu vadai': 'assets/menu/ullutha-vadai.png',
    'bajji': 'assets/menu/bajii.png',
    'veg noodles': 'assets/menu/veg-noodles.png',
    'egg noodles': 'assets/menu/egg-noddles.png',
    'chicken noodles': 'assets/menu/chicken-noodles-2.png',
    'mushroom noodles': 'assets/menu/mushroom-noodles.png',
    'chilli parotta': 'assets/menu/chill-parotta.png',
    'gulab jamun 2 pieces': 'assets/menu/jammu.png',
    'gulab jamun (2 pieces)': 'assets/menu/jammu.png',
  };

  static String? localAssetFor(MenuItem item) {
    final normalized = item.name.trim().toLowerCase();
    return _byNormalizedName[normalized];
  }
}
