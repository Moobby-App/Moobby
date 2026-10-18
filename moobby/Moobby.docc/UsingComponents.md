# Using the Components

Copy-ready examples of each native control in the Components tab, with what it looks like on iPhone.

## Overview

Each section shows the smallest code that produces the screen next to it. The full version lives in the demo view linked under each example; open it from the **Components** tab to try it.

All examples use the app's shared styling: `.typography(_:)` for text and `.buttonStyle(.glass)` or `.glassProminent` for buttons. Screenshots come from `ComponentScreenshotTests` in `moobbyUITests`; the README shows how to regenerate them.

## Alert

Use `alert` to interrupt with something the user must acknowledge or decide. Bind it to a `Bool`, give it buttons, and add a message.

@Row {
    @Column(size: 2) {
        ```swift
        @State private var showAlert = false

        Button("Simple Alert") { showAlert = true }
            .alert("Update Available", isPresented: $showAlert) {
                Button("OK") {}
            } message: {
                Text("A new version of this app is ready to install.")
            }
        ```

        A `Button(role: .destructive)` turns a button red, and a `TextField` inside the actions collects input. See ``AlertDemoView``.
    }
    @Column {
        ![An alert titled Update Available with an OK button.](component-alert)
    }
}

## Action Sheet

Use `confirmationDialog` to offer a few choices about something the user just did. It slides up from the bottom on iPhone.

@Row {
    @Column(size: 2) {
        ```swift
        @State private var showDialog = false

        Button("Show Options", systemImage: "ellipsis.circle") { showDialog = true }
            .buttonStyle(.glassProminent)
            .confirmationDialog("Photo Options", isPresented: $showDialog, titleVisibility: .visible) {
                Button("Save to Photos") {}
                Button("Copy") {}
                Button("Delete", role: .destructive) {}
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Choose what to do with this photo.")
            }
        ```

        See ``ActionSheetDemoView``.
    }
    @Column {
        ![A confirmation dialog with Save to Photos, Copy, and Delete options.](component-action-sheet)
    }
}

## Context Menu

Use `contextMenu` for secondary actions on an item. People open it with a long press. The optional `preview` replaces the lifted view.

@Row {
    @Column(size: 2) {
        ```swift
        cardView
            .glassCard()
            .contextMenu {
                Button("Add Favorite", systemImage: "star") {}
                Button("Share", systemImage: "square.and.arrow.up") {}
                Button("Delete", systemImage: "trash", role: .destructive) {}
            } preview: {
                Image(systemName: "photo")
                    .font(.system(size: 80))
                    .frame(width: 240, height: 180)
            }
        ```

        See ``ContextMenuDemoView``.
    }
    @Column {
        ![A long-pressed card with a menu of Add Favorite, Share, and Delete.](component-context-menu)
    }
}

## Face ID

Ask for biometrics through ``AppContainer/biometrics`` rather than calling LocalAuthentication from a view. The view model owns the state, and the view only shows it.

@Row {
    @Column(size: 2) {
        ```swift
        // ViewModel
        func authenticate() async {
            status = .authenticating
            do {
                let ok = try await container.biometrics.authenticate(reason: "Unlock your notes.")
                status = ok ? .success : .failure("Authentication was not completed.")
            } catch {
                status = .failure(error.localizedDescription)
            }
        }

        // View
        Button("Authenticate", systemImage: "faceid") {
            Task { await viewModel.authenticate() }
        }
        .buttonStyle(.glassProminent)
        .disabled(viewModel.status == .authenticating)
        ```

        Using Face ID requires `NSFaceIDUsageDescription`, which `project.yml` sets. See ``FaceIDDemoView`` and ``FaceIDDemoViewModel``.
    }
    @Column {
        ![The Face ID screen with an Authenticate button.](component-face-id)
    }
}

## Keyboard

Match the keyboard to the content with `keyboardType`, and move between fields with `@FocusState` and `onSubmit`. A `.keyboard` toolbar item adds buttons above the keyboard.

@Row {
    @Column(size: 2) {
        ```swift
        enum Field { case email, amount }
        @FocusState private var focusedField: Field?

        TextField("Email", text: $email, prompt: Text("name@example.com"))
            .keyboardType(.emailAddress)
            .textContentType(.emailAddress)
            .textInputAutocapitalization(.never)
            .submitLabel(.next)
            .focused($focusedField, equals: .email)
            .onSubmit { focusedField = .amount }

        // On the Form:
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") { focusedField = nil }
            }
        }
        ```

        See ``KeyboardDemoView``.
    }
    @Column {
        ![A form with the email keyboard showing.](component-keyboard)
    }
}

## List

`List` gives you swipe actions, delete, reorder, and multi-select. `onDelete` and `onMove` go on the `ForEach`, and `EditButton` switches edit mode.

@Row {
    @Column(size: 2) {
        ```swift
        List(selection: $selection) {
            ForEach(tasks) { task in
                Text(task.title)
                    .swipeActions(edge: .trailing) {
                        Button("Delete", systemImage: "trash", role: .destructive) {
                            delete(task)
                        }
                    }
            }
            .onDelete { tasks.remove(atOffsets: $0) }
            .onMove { tasks.move(fromOffsets: $0, toOffset: $1) }
        }
        .toolbar { EditButton() }
        ```

        See ``ListDemoView``.
    }
    @Column {
        ![A task list with a row swiped to show Delete.](component-list)
    }
}

## Menus

Use `Menu` to group several actions behind one button. Nest a `Menu` for a submenu. With `primaryAction`, a tap runs the main action and a long press opens the menu.

@Row {
    @Column(size: 2) {
        ```swift
        Menu {
            Button("Name", systemImage: "textformat") { sortOrder = "Name" }
            Button("Date", systemImage: "calendar") { sortOrder = "Date" }
            Menu("More") {
                Button("Kind", systemImage: "tag") { sortOrder = "Kind" }
            }
        } label: {
            Label("Sort By", systemImage: "arrow.up.arrow.down.circle")
        }
        .buttonStyle(.glass)
        ```

        See ``MenusDemoView``.
    }
    @Column {
        ![An open Sort By menu with Name, Date, Size, and More.](component-menus)
    }
}

## Picker

One `Picker` API covers several looks; choose one with `pickerStyle`: `.segmented` for 2–5 short options, `.menu` for longer lists, `.wheel` for ranges, and `.palette` for colors or symbols.

@Row {
    @Column(size: 2) {
        ```swift
        Form {
            Picker("Size", selection: $size) {
                ForEach(Size.allCases) { Text($0.label).tag($0) }
            }
            .pickerStyle(.segmented)

            Picker("Day", selection: $day) {
                ForEach(1..<32) { Text("\($0)").tag($0) }
            }
            .pickerStyle(.wheel)
        }
        ```

        See ``PickerDemoView``.
    }
    @Column {
        ![Segmented, wheel, menu, and palette pickers in a form.](component-picker)
    }
}

## Sheets

Use `sheet` for a focused task on top of the current screen. `presentationDetents` sets its heights, and `interactiveDismissDisabled` stops swipe-to-dismiss. Use `sheet(item:)` when the sheet shows a specific value.

@Row {
    @Column(size: 2) {
        ```swift
        @State private var showSheet = false

        Button("Medium Detent Sheet") { showSheet = true }
            .buttonStyle(.glass)
            .sheet(isPresented: $showSheet) {
                SheetContent(title: "Medium Sheet")
                    .presentationDetents([.medium])
                    .presentationDragIndicator(.visible)
            }
        ```

        Inside the sheet, close it with `@Environment(\.dismiss)`. See ``SheetsDemoView``.
    }
    @Column {
        ![A half-height sheet with a drag indicator over the Sheets screen.](component-sheets)
    }
}

## Slider

Use `Slider` for a value in a range. Add `step` for fixed increments, and `onEditingChanged` to react while the user drags.

@Row {
    @Column(size: 2) {
        ```swift
        Slider(value: $brightness, in: 0...1) {
            Text("Brightness")
        } minimumValueLabel: {
            Image(systemName: "sun.min")
        } maximumValueLabel: {
            Image(systemName: "sun.max.fill")
        }

        Slider(value: $volume, in: 0...100, step: 5, onEditingChanged: { editing in
            isEditingVolume = editing
        }) {
            Text("Volume")
        }
        ```

        See ``SliderDemoView``.
    }
    @Column {
        ![A continuous brightness slider and a stepped volume slider.](component-slider)
    }
}

## Stepper

Use `Stepper` for small, exact changes to a number. Pass `in:` to clamp it and `step:` for larger jumps, or use `onIncrement`/`onDecrement` for your own logic.

@Row {
    @Column(size: 2) {
        ```swift
        Stepper(value: $guestCount, in: 1...12) {
            Text("Guests: \(guestCount)")
        }

        Stepper(value: $quantity, in: 0...50, step: 5) {
            Text("Quantity: \(quantity)")
        }
        ```

        See ``StepperDemoView``.
    }
    @Column {
        ![Steppers for guests, quantity, and rating.](component-stepper)
    }
}

## Tab Bar

Build tabs with `Tab` inside a `TabView`. `badge` shows a count, `role: .search` makes a search tab, and `tabBarMinimizeBehavior` shrinks the bar on scroll.

@Row {
    @Column(size: 2) {
        ```swift
        TabView(selection: $selection) {
            Tab("Inbox", systemImage: "tray", value: .inbox) {
                InboxView()
            }
            .badge(3)

            Tab(value: .search, role: .search) {
                NavigationStack {
                    SearchView().searchable(text: $searchText)
                }
            }
        }
        .tabBarMinimizeBehavior(.onScrollDown)
        ```

        See ``TabBarDemoView``.
    }
    @Column {
        ![A tab bar with Inbox showing a badge of 3, Activity, and Search.](component-tab-bar)
    }
}

## Text Fields

Use `TextField` for one line, `SecureField` for passwords, and `TextEditor` for longer text. Show validation right under the field.

@Row {
    @Column(size: 2) {
        ```swift
        TextField("Username", text: $username, prompt: Text("At least 3 characters"))
            .textContentType(.username)
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled()

        if !username.isEmpty && username.count < 3 {
            Label("Username is too short", systemImage: "exclamationmark.triangle")
                .typography(.caption)
                .foregroundStyle(.red)
        }

        SecureField("Password", text: $password)
            .textContentType(.newPassword)
        ```

        See ``TextFieldsDemoView``.
    }
    @Column {
        ![A username field showing a too-short warning, plus password and bio fields.](component-text-fields)
    }
}

## Bottom Toolbar

Put screen-level actions at the bottom with `.bottomBar` items. A `ToolbarItemGroup` shares one glass background, and `ToolbarSpacer` separates groups.

@Row {
    @Column(size: 2) {
        ```swift
        .toolbar {
            ToolbarItemGroup(placement: .bottomBar) {
                Button("New Folder", systemImage: "folder.badge.plus") {}
                Button("Sort", systemImage: "arrow.up.arrow.down") {}
            }

            ToolbarSpacer(.fixed, placement: .bottomBar)

            ToolbarItem(placement: .bottomBar) {
                Button("Add", systemImage: "plus") {}
            }
        }
        ```

        See ``BottomToolbarDemoView``.
    }
    @Column {
        ![A list with a bottom toolbar of New Folder, Sort, and Add buttons.](component-bottom-toolbar)
    }
}

## Top Toolbar

Put navigation-bar actions at `.topBarLeading` and `.topBarTrailing`. `toolbarTitleMenu` turns the title into a menu, and `searchable` adds a search field.

@Row {
    @Column(size: 2) {
        ```swift
        List(filteredItems, id: \.self) { Text($0) }
            .navigationTitle("Items")
            .toolbarTitleMenu {
                Button("View as List", systemImage: "list.bullet") {}
                Button("View as Grid", systemImage: "square.grid.2x2") {}
            }
            .searchable(text: $searchText, placement: .toolbar, prompt: "Search Items")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Add", systemImage: "plus") {}
                }
            }
        ```

        See ``TopToolbarDemoView``.
    }
    @Column {
        ![A list with Filter and Add buttons in the navigation bar.](component-top-toolbar)
    }
}

## Topics

### Demo Views

- ``AlertDemoView``
- ``ActionSheetDemoView``
- ``ContextMenuDemoView``
- ``FaceIDDemoView``
- ``KeyboardDemoView``
- ``ListDemoView``
- ``MenusDemoView``
- ``PickerDemoView``
- ``SheetsDemoView``
- ``SliderDemoView``
- ``StepperDemoView``
- ``TabBarDemoView``
- ``TextFieldsDemoView``
- ``BottomToolbarDemoView``
- ``TopToolbarDemoView``
