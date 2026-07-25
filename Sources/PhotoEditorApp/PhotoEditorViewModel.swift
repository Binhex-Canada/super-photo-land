import AppKit
import SwiftUI
import PhotoEditorCore
import Foundation

@MainActor
final class PhotoEditorViewModel: ObservableObject {
    static let appVersion = "0.0.1-a"

    struct PersistedPhoto: Identifiable, Codable, Equatable {
        let id: String
        let displayName: String
        let fileName: String
        let createdAt: Date
        let storageFileName: String

        var fileURL: URL? {
            nil
        }
    }

    @Published var photo: Photo?
    @Published var editedImage: NSImage?
    @Published var edits = ImageEdits()
    @Published var isEditorVisible = false
    @Published var statusMessage: String = "Super Photo Land v\(appVersion) Ready"
    @Published var currentImageURL: URL?
    @Published var storedPhotos: [PersistedPhoto] = []

    private let photosDirectoryURL: URL
    private let indexFileURL: URL
    private let defaults = UserDefaults.standard

    init() {
        let supportDirectory = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("SuperPhotoLand", isDirectory: true)
        self.photosDirectoryURL = supportDirectory.appendingPathComponent("Photos", isDirectory: true)
        self.indexFileURL = supportDirectory.appendingPathComponent("photos-index.json")

        try? FileManager.default.createDirectory(at: photosDirectoryURL, withIntermediateDirectories: true)

        loadStoredPhotos()
        restoreLastViewedPhoto()
    }

    var imageSizeDescription: String {
        guard let photo = photo else { return "—" }
        let size = photo.originalImage.size
        return "\(Int(size.width)) × \(Int(size.height))"
    }

    func openImage() {
        let openPanel = NSOpenPanel()
        openPanel.allowedContentTypes = [.image]
        openPanel.canChooseDirectories = false
        openPanel.canChooseFiles = true
        openPanel.allowsMultipleSelection = true
        openPanel.title = "Upload photos to view and edit"

        guard openPanel.runModal() == .OK else {
            statusMessage = "Image selection canceled."
            return
        }

        let selectedURLs = openPanel.urls
        guard !selectedURLs.isEmpty else {
            statusMessage = "No images were selected."
            return
        }

        importPhotos(from: selectedURLs)
    }

    func openStoredPhoto(_ persistedPhoto: PersistedPhoto) {
        guard let fileURL = fileURL(for: persistedPhoto) else {
            statusMessage = "The saved photo could not be found."
            return
        }

        do {
            let loadedPhoto = try Photo(url: fileURL)
            photo = loadedPhoto
            currentImageURL = fileURL
            defaults.set(persistedPhoto.id, forKey: "lastViewedPhotoID")
            isEditorVisible = false
            resetEdits()
            statusMessage = "Loaded \(persistedPhoto.displayName)."
        } catch {
            statusMessage = "Unable to load saved photo: \(error.localizedDescription)"
        }
    }

    func applyEdits() {
        guard let photo else {
            statusMessage = "Upload a photo first."
            return
        }

        do {
            editedImage = try ImageEditor.applyEdits(to: photo, edits: edits)
            statusMessage = "Applied edits."
        } catch {
            statusMessage = "Failed to render edits: \(error.localizedDescription)"
        }
    }

    func resetEdits() {
        edits = ImageEdits()
        isEditorVisible = false
        if let photo {
            editedImage = photo.originalImage
        } else {
            editedImage = nil
        }
    }

    func showEditor() {
        isEditorVisible = true
    }

    func hideEditor() {
        isEditorVisible = false
    }

    func exportEditedImage() {
        guard let image = editedImage else {
            statusMessage = "No edited image available to save."
            return
        }

        let savePanel = NSSavePanel()
        savePanel.allowedContentTypes = [.png]
        savePanel.nameFieldStringValue = currentImageURL?.deletingPathExtension().lastPathComponent.appending("-edited.png") ?? "edited-image.png"
        savePanel.title = "Save edited image"

        guard savePanel.runModal() == .OK, let url = savePanel.url else {
            statusMessage = "Save canceled."
            return
        }

        do {
            try writePNG(image: image, to: url)
            statusMessage = "Saved edited image to \(url.lastPathComponent)."
        } catch {
            statusMessage = "Failed to save image: \(error.localizedDescription)"
        }
    }

    func thumbnailImage(for persistedPhoto: PersistedPhoto) -> NSImage? {
        guard let fileURL = fileURL(for: persistedPhoto) else { return nil }
        return NSImage(contentsOf: fileURL)
    }

    func deleteCurrentPhoto() {
        guard let currentImageURL else {
            statusMessage = "No photo is currently selected."
            return
        }

        let matchingPhoto = storedPhotos.first { persistedPhoto in
            persistedPhoto.storageFileName == currentImageURL.lastPathComponent ||
            persistedPhoto.fileName == currentImageURL.lastPathComponent ||
            currentImageURL.path == fileURL(for: persistedPhoto)?.path
        }

        guard let matchingPhoto else {
            statusMessage = "That photo is not in your saved gallery."
            return
        }

        deleteStoredPhoto(matchingPhoto)
    }

    func deleteStoredPhoto(_ persistedPhoto: PersistedPhoto) {
        let deletedPhotoWasCurrent: Bool = {
            guard let currentURL = currentImageURL else { return false }
            return currentURL.lastPathComponent == persistedPhoto.fileName ||
                currentURL.lastPathComponent == persistedPhoto.storageFileName ||
                currentURL.path == fileURL(for: persistedPhoto)?.path
        }()

        if let fileURL = fileURL(for: persistedPhoto) {
            try? FileManager.default.removeItem(at: fileURL)
        }

        storedPhotos.removeAll { $0.id == persistedPhoto.id }
        saveStoredPhotos()

        if deletedPhotoWasCurrent {
            clearCurrentSelection()
        }

        if deletedPhotoWasCurrent, let nextPhoto = storedPhotos.first {
            openStoredPhoto(nextPhoto)
            defaults.set(nextPhoto.id, forKey: "lastViewedPhotoID")
            statusMessage = "Deleted \(persistedPhoto.displayName) and opened \(nextPhoto.displayName)."
        } else {
            statusMessage = "Deleted \(persistedPhoto.displayName)."
        }
    }

    private func importPhotos(from sourceURLs: [URL]) {
        var importedPhotos: [PersistedPhoto] = []

        for sourceURL in sourceURLs {
            do {
                let destinationFileName = "\(UUID().uuidString)\(sourceURL.pathExtension.isEmpty ? "" : ".\(sourceURL.pathExtension)")"
                let destinationURL = photosDirectoryURL.appendingPathComponent(destinationFileName)
                try FileManager.default.copyItem(at: sourceURL, to: destinationURL)

                let metadata = PersistedPhoto(
                    id: UUID().uuidString,
                    displayName: sourceURL.deletingPathExtension().lastPathComponent,
                    fileName: sourceURL.lastPathComponent,
                    createdAt: Date(),
                    storageFileName: destinationFileName
                )

                importedPhotos.append(metadata)
            } catch {
                statusMessage = "Unable to save photo \(sourceURL.lastPathComponent): \(error.localizedDescription)"
            }
        }

        guard !importedPhotos.isEmpty else { return }

        storedPhotos.append(contentsOf: importedPhotos)
        storedPhotos.sort { $0.createdAt > $1.createdAt }
        saveStoredPhotos()

        if photo == nil {
            let firstImported = importedPhotos[0]
            openStoredPhoto(firstImported)
            defaults.set(firstImported.id, forKey: "lastViewedPhotoID")
        }

        if importedPhotos.count == 1 {
            statusMessage = photo == nil ? "Saved and loaded \(importedPhotos[0].displayName)." : "Saved \(importedPhotos[0].displayName)."
        } else {
            statusMessage = photo == nil ? "Saved \(importedPhotos.count) photos." : "Added \(importedPhotos.count) photos to your gallery."
        }
    }

    private func loadStoredPhotos() {
        guard FileManager.default.fileExists(atPath: indexFileURL.path) else {
            storedPhotos = []
            return
        }

        do {
            let data = try Data(contentsOf: indexFileURL)
            let decoded = try JSONDecoder().decode([PersistedPhoto].self, from: data)
            storedPhotos = decoded.sorted { $0.createdAt > $1.createdAt }
        } catch {
            storedPhotos = []
            statusMessage = "Unable to load saved photos: \(error.localizedDescription)"
        }
    }

    private func saveStoredPhotos() {
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            let data = try encoder.encode(storedPhotos)
            try data.write(to: indexFileURL, options: .atomic)
        } catch {
            statusMessage = "Unable to save photo index: \(error.localizedDescription)"
        }
    }

    private func restoreLastViewedPhoto() {
        guard let lastViewedPhotoID = defaults.string(forKey: "lastViewedPhotoID") else { return }
        guard let persistedPhoto = storedPhotos.first(where: { $0.id == lastViewedPhotoID }) else { return }
        openStoredPhoto(persistedPhoto)
    }

    private func clearCurrentSelection() {
        photo = nil
        editedImage = nil
        currentImageURL = nil
        isEditorVisible = false
        edits = ImageEdits()
    }

    private func fileURL(for persistedPhoto: PersistedPhoto) -> URL? {
        let resolved = photosDirectoryURL.appendingPathComponent(persistedPhoto.storageFileName)
        return FileManager.default.fileExists(atPath: resolved.path) ? resolved : nil
    }

    private func writePNG(image: NSImage, to url: URL) throws {
        guard let tiffData = image.tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: tiffData),
              let pngData = bitmap.representation(using: .png, properties: [:])
        else {
            throw PhotoEditorError.exportFailed
        }

        try pngData.write(to: url, options: .atomic)
    }
}
