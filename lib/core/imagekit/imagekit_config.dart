import 'image_storage_type.dart';
import 'imagekit_models.dart';

class ImageKitConfigManager {
  static ImageKitConfig getConfig(ImageStorageType storageType) {
    switch (storageType) {
      case ImageStorageType.seller_product_1:
        return const ImageKitConfig(
          publicKey: 'public_PJlwuhis1dSDZv8pfMInQyTgxnc=',
          privateKey:
              '', // Leave empty! The backend will fetch the private key securely from Firebase!
          urlEndpoint: 'https://ik.imagekit.io/gr5bqyssf',
          defaultFolder: 'products/seller_account_1/',
          accountName: 'Seller Account 1',
        );
      case ImageStorageType.seller_product_2:
        return const ImageKitConfig(
          publicKey:
              'public_Cbw3KbrgViTi3MbL8hSLwxyXrxI=', // Make sure to put your real PUBLIC key here
          privateKey:
              '', // Leave empty! The backend will fetch the private key securely from Firebase!
          urlEndpoint: 'https:seller_product_2',
          defaultFolder: 'products/seller_account_2/',
          accountName: 'Seller Account 2',
        );
      case ImageStorageType.seller_product_3:
        return const ImageKitConfig(
          publicKey:
              'public_seller_product_3', // Make sure to put your real PUBLIC key here
          privateKey:
              '', // Leave empty! The backend will fetch the private key securely from Firebase!
          urlEndpoint: 'https:seller_product_3',
          defaultFolder: 'products/seller_account_3/',
          accountName: 'Seller Account 3',
        );
      case ImageStorageType.seller_product_4:
        return const ImageKitConfig(
          publicKey:
              'public_seller_product_4', // Make sure to put your real PUBLIC key here
          privateKey:
              '', // Leave empty! The backend will fetch the private key securely from Firebase!
          urlEndpoint: 'https:seller_product_4',
          defaultFolder: 'products/seller_account_4/',
          accountName: 'Seller Account 4',
        );
      case ImageStorageType.workers:
        return const ImageKitConfig(
          publicKey:
              'public_workers', // Make sure to put your real PUBLIC key here
          privateKey:
              '', // Leave empty! The backend will fetch the private key securely from Firebase!
          urlEndpoint: 'https:workers',
          defaultFolder: 'workers/',
          accountName: 'Workers',
        );
      default:
        return const ImageKitConfig(
          publicKey: '',
          privateKey: '',
          urlEndpoint: '',
          defaultFolder: 'uploads/',
          accountName: 'Default',
        );
    }
  }
}
