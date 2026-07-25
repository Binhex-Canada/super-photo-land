import SwiftUI
import AppKit
import PhotoEditorCore

struct ContentView: View {
    @ObservedObject var viewModel: PhotoEditorViewModel
    @State private var isFullSizePresented = false
    @State private var showingAbout = false

    private let accentColor = Color(red: 0.10, green: 0.48, blue: 0.86)
    private let backgroundTop = Color(red: 0.96, green: 0.97, blue: 0.99)
    private let backgroundBottom = Color(red: 0.92, green: 0.94, blue: 0.97)

    var body: some View {
        VStack(spacing: 0) {
            headerBar
            Divider()

            if viewModel.storedPhotos.isEmpty {
                galleryPlaceholder
            } else {
                galleryGridView
            }

            Divider()
            statusBar
        }
        .frame(minWidth: 1000, minHeight: 620)
        .background(
            LinearGradient(
                colors: [backgroundTop, backgroundBottom],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .tint(accentColor)
        .sheet(isPresented: $showingAbout) {
            AboutView(isPresented: $showingAbout, logoImage: aboutLogo)
                .frame(minWidth: 460, minHeight: 360)
        }
        .sheet(isPresented: $isFullSizePresented) {
            if let image = fullSizeImage {
                FullSizeImageView(
                    image: image,
                    viewModel: viewModel,
                    editorPanel: AnyView(editorPanel),
                    isPresented: $isFullSizePresented
                )
                .frame(minWidth: 860, minHeight: 680)
            } else {
                VStack(spacing: 12) {
                    Image(systemName: "photo")
                        .font(.system(size: 48))
                        .foregroundStyle(.secondary)
                    Text("No photo is selected")
                        .foregroundStyle(.secondary)
                }
                .frame(minWidth: 360, minHeight: 280)
            }
        }
    }

    private var headerBar: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Super Photo Land")
                    .font(.title2)
                    .bold()
                Text("A polished photo viewer with light editing")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Button {
                showingAbout = true
            } label: {
                Label("About", systemImage: "info.circle")
            }
            .buttonStyle(.bordered)

            if viewModel.photo != nil {
                Button {
                    if viewModel.isEditorVisible {
                        viewModel.hideEditor()
                    } else {
                        viewModel.showEditor()
                    }
                } label: {
                    Label(viewModel.isEditorVisible ? "Hide Editor" : "Edit Photo", systemImage: viewModel.isEditorVisible ? "xmark.circle" : "pencil")
                }
                .buttonStyle(.borderedProminent)
                .help(viewModel.isEditorVisible ? "Hide the editor" : "Show the editor")
            }

            Button {
                viewModel.openImage()
            } label: {
                Label("Upload Photos", systemImage: "plus.circle.fill")
                    .fontWeight(.semibold)
            }
            .buttonStyle(.borderedProminent)
            .keyboardShortcut("O", modifiers: [.command])
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .stroke(Color.white.opacity(0.4), lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 2)
        )
        .padding(16)
    }

    private var aboutLogo: NSImage? {
        if let bundleURL = Bundle.main.url(forResource: "company-logo", withExtension: "png") {
            return NSImage(contentsOf: bundleURL)
        }

        let localURL = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
            .appendingPathComponent("Assets/Photos/company-logo.png")
        return NSImage(contentsOf: localURL)
    }

    private var fullSizeImage: NSImage? {
        viewModel.editedImage ?? viewModel.photo?.originalImage
    }

    private func openPhotoInFullSize(_ persistedPhoto: PhotoEditorViewModel.PersistedPhoto) {
        viewModel.openStoredPhoto(persistedPhoto)
        isFullSizePresented = true
    }

    private var galleryGridView: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Photo Gallery")
                        .font(.title2)
                        .bold()
                    Text("Upload photos and browse them in a grid.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer()
            }

            HStack(alignment: .top, spacing: 16) {
                ScrollView {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 180), spacing: 16)], spacing: 16) {
                        ForEach(viewModel.storedPhotos) { persistedPhoto in
                            GalleryGridCard(
                                persistedPhoto: persistedPhoto,
                                thumbnail: viewModel.thumbnailImage(for: persistedPhoto),
                                isSelected: currentPersistedPhoto?.id == persistedPhoto.id
                            ) {
                                openPhotoInFullSize(persistedPhoto)
                            } deleteAction: {
                                viewModel.deleteStoredPhoto(persistedPhoto)
                            }
                        }
                    }
                }

                VStack(alignment: .leading, spacing: 16) {
                    if let selectedPhoto = currentPersistedPhoto {
                        selectedPhotoPreview(for: selectedPhoto)
                            .frame(width: 320)
                    } else {
                        PlaceholderPreview()
                            .frame(width: 320)
                    }

                    if viewModel.isEditorVisible {
                        editorPanel
                            .frame(width: 320)
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var galleryPlaceholder: some View {
        ZStack {
            if viewModel.storedPhotos.isEmpty {
                VStack(spacing: 18) {
                    Image(systemName: "photo.on.rectangle.angled")
                        .font(.system(size: 84, weight: .light))
                        .foregroundStyle(accentColor.opacity(0.9))

                    VStack(spacing: 8) {
                        Text("Photo Gallery")
                            .font(.title2)
                            .bold()

                        Text("Your gallery is empty. Upload a photo to start browsing and editing.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }

                    Button {
                        viewModel.openImage()
                    } label: {
                        Label("Upload Photos", systemImage: "plus.circle.fill")
                            .fontWeight(.semibold)
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding(40)
                .frame(maxWidth: 560)
                .background(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .fill(.ultraThinMaterial)
                        .overlay(
                            RoundedRectangle(cornerRadius: 24, style: .continuous)
                                .stroke(Color.white.opacity(0.45), lineWidth: 1)
                        )
                        .shadow(color: .black.opacity(0.08), radius: 16, x: 0, y: 8)
                )
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Saved Photos")
                                    .font(.title2)
                                    .bold()
                                Text("Tap any photo to view it and start editing.")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }

                            Spacer()

                            Button {
                                viewModel.openImage()
                            } label: {
                                Label("Upload Photos", systemImage: "plus.circle.fill")
                                    .fontWeight(.semibold)
                            }
                            .buttonStyle(.borderedProminent)
                        }

                        Text("Right-click any gallery photo to remove it from your collection.")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 190), spacing: 16)], spacing: 16) {
                            ForEach(viewModel.storedPhotos) { persistedPhoto in
                                GalleryCard(
                                    persistedPhoto: persistedPhoto,
                                    thumbnail: viewModel.thumbnailImage(for: persistedPhoto)
                                ) {
                                    viewModel.openStoredPhoto(persistedPhoto)
                                } deleteAction: {
                                    viewModel.deleteStoredPhoto(persistedPhoto)
                                }
                            }
                        }
                    }
                    .padding(28)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(28)
    }

    private var viewerActionBar: some View {
        HStack(spacing: 12) {
            Spacer()

            Button {
                viewModel.exportEditedImage()
            } label: {
                Label("Save Edited Image", systemImage: "square.and.arrow.down")
            }
            .disabled(viewModel.editedImage == nil)
            .buttonStyle(.bordered)

            Button {
                viewModel.resetEdits()
            } label: {
                Label("Reset Edits", systemImage: "arrow.counterclockwise")
            }
            .disabled(viewModel.photo == nil)
            .buttonStyle(.bordered)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }

    private var gallerySidebar: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Gallery")
                        .font(.headline)
                    Text("Current photo and new uploads")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Button {
                    viewModel.openImage()
                } label: {
                    Image(systemName: "plus")
                }
                .buttonStyle(.bordered)
            }

            if let currentPhoto = currentPersistedPhoto {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Current")
                        .font(.subheadline)
                        .fontWeight(.semibold)

                    GalleryThumbnailCard(
                        persistedPhoto: currentPhoto,
                        thumbnail: viewModel.thumbnailImage(for: currentPhoto)
                    ) {
                        viewModel.openStoredPhoto(currentPhoto)
                    }
                }
            }

            ScrollView {
                LazyVGrid(columns: [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)], spacing: 10) {
                    ForEach(viewModel.storedPhotos) { persistedPhoto in
                        GalleryThumbnailCard(
                            persistedPhoto: persistedPhoto,
                            thumbnail: viewModel.thumbnailImage(for: persistedPhoto)
                        ) {
                            viewModel.openStoredPhoto(persistedPhoto)
                        }
                    }
                }
            }
            .frame(maxHeight: 260)
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .stroke(Color.white.opacity(0.5), lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.08), radius: 10, x: 0, y: 4)
        )
    }

    private var currentPersistedPhoto: PhotoEditorViewModel.PersistedPhoto? {
        guard let currentImageURL = viewModel.currentImageURL else { return nil }
        return viewModel.storedPhotos.first { persistedPhoto in
            persistedPhoto.storageFileName == currentImageURL.lastPathComponent ||
            persistedPhoto.fileName == currentImageURL.lastPathComponent
        }
    }

    private var imagePanel: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Photo Viewer")
                    .font(.headline)
                Spacer()
                Text("Double-click to enlarge")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if let editedImage = viewModel.editedImage {
                ZStack {
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(Color.black.opacity(0.04))

                    GeometryReader { geometry in
                        Image(nsImage: editedImage)
                            .resizable()
                            .scaledToFit()
                            .frame(width: geometry.size.width, height: geometry.size.height)
                            .clipped()
                            .contentShape(Rectangle())
                            .contextMenu {
                                Button(role: .destructive) {
                                    viewModel.deleteCurrentPhoto()
                                } label: {
                                    Label("Delete Photo", systemImage: "trash")
                                }
                            }
                            .onTapGesture(count: 2) {
                                isFullSizePresented = true
                            }
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(Color.white.opacity(0.5), lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.08), radius: 10, x: 0, y: 4)
                .padding(.top, 2)
                .sheet(isPresented: $isFullSizePresented) {
                    FullSizeImageView(
                        image: editedImage,
                        viewModel: viewModel,
                        editorPanel: AnyView(editorPanel),
                        isPresented: $isFullSizePresented
                    )
                    .frame(minWidth: 800, minHeight: 600)
                }
            } else {
                VStack(spacing: 10) {
                    Image(systemName: "photo")
                        .font(.system(size: 54))
                        .foregroundStyle(.secondary)
                    Text("Upload a photo to begin viewing and editing.")
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(28)
                .background(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(Color.black.opacity(0.03))
                        .overlay(
                            RoundedRectangle(cornerRadius: 20, style: .continuous)
                                .stroke(Color.white.opacity(0.4), lineWidth: 1)
                        )
                )
            }
        }
        .padding(16)
        .frame(minWidth: 560, maxWidth: .infinity, minHeight: 480)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .stroke(Color.white.opacity(0.45), lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.08), radius: 12, x: 0, y: 6)
        )
    }

    private struct FullSizeImageView: View {
        let image: NSImage
        @ObservedObject var viewModel: PhotoEditorViewModel
        let editorPanel: AnyView
        @Binding var isPresented: Bool

        var body: some View {
            ZStack(alignment: .topTrailing) {
                Color.black.ignoresSafeArea()
                GeometryReader { geometry in
                    Image(nsImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: geometry.size.width, maxHeight: geometry.size.height)
                        .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
                }

                HStack(alignment: .top, spacing: 12) {
                    Spacer()

                    if viewModel.isEditorVisible {
                        editorPanel
                            .frame(width: 320)
                            .transition(.move(edge: .trailing))
                            .animation(.easeInOut, value: viewModel.isEditorVisible)
                    }

                    VStack(alignment: .trailing, spacing: 12) {
                        Button {
                            viewModel.isEditorVisible.toggle()
                        } label: {
                            Label(viewModel.isEditorVisible ? "Hide Editor" : "Edit", systemImage: "pencil")
                                .padding(8)
                        }
                        .buttonStyle(.borderedProminent)

                        Button(action: {
                            isPresented = false
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 28))
                                .foregroundStyle(.white)
                                .shadow(radius: 4)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(20)
                }
            }
        }
    }

    private func selectedPhotoPreview(for persistedPhoto: PhotoEditorViewModel.PersistedPhoto) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Selected")
                    .font(.headline)
                Spacer()
                Button {
                    openPhotoInFullSize(persistedPhoto)
                } label: {
                    Label("Open Full Size", systemImage: "arrow.up.right.square")
                }
                .buttonStyle(.bordered)
            }

            VStack(alignment: .leading, spacing: 6) {
                Text(persistedPhoto.displayName)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                Text(persistedPhoto.createdAt, style: .date)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text("This opens in a larger view instead of keeping the image inline.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .stroke(Color.white.opacity(0.45), lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.08), radius: 10, x: 0, y: 4)
        )
    }

    private func PlaceholderPreview() -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Selection")
                .font(.headline)
            Text("Pick a photo from the grid to preview and edit it.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Spacer()
        }
        .padding(16)
        .frame(maxWidth: .infinity, maxHeight: 260)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .stroke(Color.white.opacity(0.45), lineWidth: 1)
                )
        )
    }

    private struct GalleryGridCard: View {
        let persistedPhoto: PhotoEditorViewModel.PersistedPhoto
        let thumbnail: NSImage?
        let isSelected: Bool
        let action: () -> Void
        let deleteAction: () -> Void

        var body: some View {
            VStack(alignment: .leading, spacing: 8) {
                if let thumbnail {
                    Image(nsImage: thumbnail)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 160, height: 120)
                        .clipped()
                        .background(Color.black.opacity(0.05))
                } else {
                    ZStack {
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(Color.black.opacity(0.05))
                        Image(systemName: "photo")
                            .font(.system(size: 40))
                            .foregroundStyle(.secondary)
                    }
                    .frame(width: 160, height: 120)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(persistedPhoto.displayName)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .lineLimit(2)
                    Text(persistedPhoto.createdAt, style: .date)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(isSelected ? Color.accentColor.opacity(0.16) : Color.white.opacity(0.45))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .stroke(isSelected ? Color.accentColor.opacity(0.8) : Color.white.opacity(0.45), lineWidth: isSelected ? 2 : 1)
                    )
            )
            .onTapGesture {
                action()
            }
            .contextMenu {
                Button {
                    action()
                } label: {
                    Label("Open Photo", systemImage: "arrow.right.circle")
                }

                Button(role: .destructive) {
                    deleteAction()
                } label: {
                    Label("Delete Photo", systemImage: "trash")
                }
            }
        }
    }

    private struct GalleryThumbnailCard: View {
        let persistedPhoto: PhotoEditorViewModel.PersistedPhoto
        let thumbnail: NSImage?
        let action: () -> Void

        var body: some View {
            Button(action: action) {
                VStack(alignment: .leading, spacing: 8) {
                    if let thumbnail {
                        Image(nsImage: thumbnail)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 120, height: 90)
                            .clipped()
                            .background(Color.black.opacity(0.05))
                    } else {
                        ZStack {
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(Color.black.opacity(0.05))
                            Image(systemName: "photo")
                                .font(.system(size: 24))
                                .foregroundStyle(.secondary)
                        }
                        .frame(width: 120, height: 90)
                    }

                    Text(persistedPhoto.displayName)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .lineLimit(2)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(8)
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(.ultraThinMaterial)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .stroke(Color.white.opacity(0.45), lineWidth: 1)
                        )
                )
            }
            .buttonStyle(.plain)
        }
    }

    private struct GalleryCard: View {
        let persistedPhoto: PhotoEditorViewModel.PersistedPhoto
        let thumbnail: NSImage?
        let action: () -> Void
        let deleteAction: () -> Void

        var body: some View {
            Button(action: action) {
                VStack(alignment: .leading, spacing: 10) {
                    if let thumbnail {
                        Image(nsImage: thumbnail)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 170, height: 120)
                            .clipped()
                            .background(Color.black.opacity(0.05))
                    } else {
                        ZStack {
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .fill(Color.black.opacity(0.05))
                            Image(systemName: "photo")
                                .font(.system(size: 40))
                                .foregroundStyle(.secondary)
                        }
                        .frame(width: 170, height: 120)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text(persistedPhoto.displayName)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .lineLimit(2)
                        Text(persistedPhoto.createdAt, style: .date)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(.ultraThinMaterial)
                        .overlay(
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .stroke(Color.white.opacity(0.5), lineWidth: 1)
                        )
                        .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 4)
                )
            }
            .buttonStyle(.plain)
            .contextMenu {
                Button(role: .destructive) {
                    deleteAction()
                } label: {
                    Label("Delete Photo", systemImage: "trash")
                }
            }
            .frame(maxWidth: 190)
        }
    }

    private struct AboutView: View {
        @Binding var isPresented: Bool
        let logoImage: NSImage?

        var body: some View {
            VStack(spacing: 18) {
                if let logoImage {
                    Image(nsImage: logoImage)
                        .resizable()
                        .scaledToFit()
                        .frame(height: 96)
                        .padding(.top, 8)
                }

                VStack(spacing: 6) {
                    Text("Super Photo Land")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundStyle(Color.white)
                    Text("Produced with loving evil from an evil monster")
                        .font(.subheadline)
                        .foregroundStyle(Color.white.opacity(0.86))
                        .multilineTextAlignment(.center)
                }

                Text("A sleek macOS photo viewer with optional editing tools for browsing, polishing, and saving your favorite images.")
                    .multilineTextAlignment(.center)
                    .foregroundStyle(Color.white.opacity(0.82))
                    .padding(.horizontal, 8)

                VStack(spacing: 4) {
                    Text("Version 0.0.1-a")
                        .font(.footnote)
                        .foregroundStyle(Color.white.opacity(0.78))
                    Text("Super Cthulhu Software")
                        .font(.footnote)
                        .fontWeight(.semibold)
                        .foregroundStyle(Color.white)
                    Text("© 2026 Super Cthulhu Software")
                        .font(.footnote)
                        .foregroundStyle(Color.white.opacity(0.72))
                }

                Spacer(minLength: 0)

                Button("Close") {
                    isPresented = false
                }
                .keyboardShortcut(.cancelAction)
                .buttonStyle(.borderedProminent)
            }
            .padding(28)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(
                LinearGradient(
                    colors: [
                        Color(red: 0.08, green: 0.12, blue: 0.22),
                        Color(red: 0.16, green: 0.24, blue: 0.40),
                        Color(red: 0.27, green: 0.39, blue: 0.64)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
        }
    }

    private var editorPanel: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Editor")
                    .font(.headline)
                Spacer()
                Text("Fine-tune your photo")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    editSlider(
                        label: "Exposure",
                        value: $viewModel.edits.exposure,
                        range: -2...2,
                        step: 0.1,
                        format: .number.precision(.fractionLength(1))
                    )

                    editSlider(
                        label: "Saturation",
                        value: $viewModel.edits.saturation,
                        range: 0...2,
                        step: 0.05,
                        format: .number.precision(.fractionLength(2))
                    )

                    editSlider(
                        label: "Contrast",
                        value: $viewModel.edits.contrast,
                        range: 0.5...2,
                        step: 0.05,
                        format: .number.precision(.fractionLength(2))
                    )

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Filter")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                        Picker("Filter", selection: $viewModel.edits.filter) {
                            ForEach(PhotoFilter.allCases) { filter in
                                Text(filter.displayName).tag(filter)
                            }
                        }
                        .pickerStyle(.segmented)
                        .onChange(of: viewModel.edits) {
                            viewModel.applyEdits()
                        }
                    }

                    Divider()

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Image information")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                        InfoRow(title: "Filename", value: viewModel.currentImageURL?.lastPathComponent ?? "—")
                        InfoRow(title: "Size", value: viewModel.imageSizeDescription)
                        InfoRow(title: "Current filter", value: viewModel.edits.filter.displayName)
                        if viewModel.photo != nil {
                            InfoRow(title: "Mode", value: "Viewer first, edit second")
                        }
                    }
                }
                .padding(.trailing, 4)
            }
        }
        .padding(16)
        .frame(minWidth: 280, maxWidth: .infinity, minHeight: 260)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .stroke(Color.white.opacity(0.45), lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.08), radius: 12, x: 0, y: 6)
        )
    }

    private func editSlider(label: String, value: Binding<Double>, range: ClosedRange<Double>, step: Double, format: FloatingPointFormatStyle<Double>) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(label)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                Spacer()
                Text(value.wrappedValue, format: format)
                    .foregroundStyle(.secondary)
            }
            Slider(value: value, in: range, step: step)
                .tint(accentColor)
                .onChange(of: value.wrappedValue) {
                    viewModel.applyEdits()
                }
        }
    }

    private var statusBar: some View {
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(viewModel.statusMessage)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                Text("Version \(PhotoEditorViewModel.appVersion)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 10)
    }

    private struct InfoRow: View {
        let title: String
        let value: String

        var body: some View {
            HStack(alignment: .firstTextBaseline) {
                Text(title)
                    .foregroundStyle(.secondary)
                Spacer()
                Text(value)
                    .fontWeight(.medium)
            }
            .font(.subheadline)
        }
    }
}
