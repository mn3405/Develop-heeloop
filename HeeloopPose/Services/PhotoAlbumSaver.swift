import Photos
import UIKit

/// 캡처한 이미지를 앱 전용 앨범에만 모아 저장한다.
/// 앨범 이름을 바꾸고 싶으면 `albumTitle`만 수정하면 된다.
enum PhotoAlbumSaver {
    static let albumTitle = "Heeloop Pose"

    enum SaveError: LocalizedError {
        case denied, encodeFailed, albumUnavailable

        var errorDescription: String? {
            switch self {
            case .denied: return "사진 접근 권한이 없어요. 설정 > 앱에서 사진 권한을 허용해 주세요."
            case .encodeFailed: return "이미지를 변환하지 못했어요."
            case .albumUnavailable: return "전용 앨범을 만들지 못했어요."
            }
        }
    }

    static func save(image: UIImage) async throws {
        let status = await PHPhotoLibrary.requestAuthorization(for: .readWrite)
        guard status == .authorized || status == .limited else { throw SaveError.denied }
        guard let data = image.pngData() else { throw SaveError.encodeFailed }

        let albumID = try await albumLocalIdentifier()
        try await PHPhotoLibrary.shared().performChanges {
            let creation = PHAssetCreationRequest.forAsset()
            creation.addResource(with: .photo, data: data, options: nil)
            guard let placeholder = creation.placeholderForCreatedAsset else { return }
            let albums = PHAssetCollection.fetchAssetCollections(withLocalIdentifiers: [albumID], options: nil)
            guard let album = albums.firstObject,
                  let change = PHAssetCollectionChangeRequest(for: album) else { return }
            change.addAssets([placeholder] as NSArray)
        }
    }

    /// 전용 앨범을 찾고, 없으면 새로 만든다.
    private static func albumLocalIdentifier() async throws -> String {
        let options = PHFetchOptions()
        options.predicate = NSPredicate(format: "title = %@", albumTitle)
        let existing = PHAssetCollection.fetchAssetCollections(with: .album, subtype: .albumRegular, options: options)
        if let album = existing.firstObject { return album.localIdentifier }

        let box = IDBox()
        let title = albumTitle
        try await PHPhotoLibrary.shared().performChanges {
            let request = PHAssetCollectionChangeRequest.creationRequestForAssetCollection(withTitle: title)
            box.id = request.placeholderForCreatedAssetCollection.localIdentifier
        }
        guard let id = box.id else { throw SaveError.albumUnavailable }
        return id
    }

    private final class IDBox: @unchecked Sendable {
        var id: String?
    }
}
