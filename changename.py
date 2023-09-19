import os

folder_path = "./leapGestRecog/11_back_hand"
for filename in os.listdir(folder_path):
    if filename.endswith(".jpg"):
        old_path = os.path.join(folder_path, filename)
        new_filename = os.path.splitext(filename)[0] + ".png"
        new_path = os.path.join(folder_path, new_filename)

        try:
            os.rename(old_path, new_path)
            print(f"Renamed: {filename} to {new_filename}")
        except FileNotFoundError:
            print(f"File not found: {filename}")
        except FileExistsError:
            print(f"File already exists: {new_filename}")

