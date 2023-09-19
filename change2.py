import os

folder_path = "./leapGestRecog/09_c"

# Get a list of all image files in the folder
image_files = [f for f in os.listdir(folder_path) if f.lower().endswith(('.jpg', '.jpeg', '.png', '.gif'))]

# Sort the list to ensure consistent naming order
image_files.sort()

# Rename files
for i, old_name in enumerate(image_files, start=1):
    extension = os.path.splitext(old_name)[1]
    new_name = f"09_{i:04d}{extension}"
    old_path = os.path.join(folder_path, old_name)
    new_path = os.path.join(folder_path, new_name)
    
    try:
        os.rename(old_path, new_path)
        print(f"Renamed: {old_name} to {new_name}")
    except FileNotFoundError:
        print(f"File not found: {old_name}")
    except FileExistsError:
        print(f"File already exists: {new_name}")
