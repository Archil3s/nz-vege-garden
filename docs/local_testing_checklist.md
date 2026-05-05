# Local Testing Checklist

Use this when testing the app on a PC.

## 1. Clone and enter the project

```bash
git clone https://github.com/Archil3s/nz-vege-garden.git
cd nz-vege-garden
```

If the repo is already cloned:

```bash
git pull
```

## 2. Validate bundled data

```bash
python tools/validate_data.py
```

Expected result:

```text
Data validation passed.
```

If this fails, fix the listed JSON data issue before running the app.

## 3. Install Flutter dependencies

```bash
flutter pub get
```

## 4. Run static checks

```bash
flutter analyze
```

If this fails, copy the first error and fix that before continuing.

## 5. Run tests

```bash
flutter test
```

## 6. Run the app

For Chrome/web:

```bash
flutter run -d chrome
```

For Android emulator or connected device:

```bash
flutter run
```

## 7. Manual app test flow

Check these screens:

1. Home
   - Dashboard loads
   - Region and garden context display
   - What-to-plant-now list appears

2. Settings
   - Change region
   - Change frost risk
   - Change wind exposure
   - Change garden type
   - Toggle weekly garden reminder if testing on a supported device

3. Crop Guide
   - Search for `tomato`
   - Filter to herbs
   - Toggle beginner-friendly
   - Toggle container-friendly
   - Open a crop detail page

4. Garden Beds
   - Add a bed
   - Add a crop to the bed
   - Confirm harvest estimate appears
   - Open the planted crop editor
   - Change status and date
   - Save changes
   - Delete the planted crop

5. Tasks
   - Confirm generated weekly task cards appear

6. Pests
   - Expand pest/problem cards
   - Confirm signs, actions, prevention, and seasonal notes appear

## 8. Report issues

When something fails, copy:

- the command you ran
- the first error block
- the device target, such as Chrome, Android emulator, or phone
- the screen where the issue happened
