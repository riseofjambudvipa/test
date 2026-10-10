import os
import sys
import subprocess
import time
from concurrent.futures import ThreadPoolExecutor

SOURCE_DIR = r"a:\Projects\CapStudio\assets\emojis\google_noto_emojis_animated_pack\512x512"
TARGET_DIR = r"a:\Projects\CapStudio\assets\emojis\google_noto_emojis_animated_pack\512x512_apng"

def get_file_list():
    tasks = []
    for root, dirs, files in os.walk(SOURCE_DIR):
        for f in files:
            if f.lower().endswith(".gif"):
                rel_dir = os.path.relpath(root, SOURCE_DIR)
                src_path = os.path.join(root, f)
                dst_fname = os.path.splitext(f)[0] + ".png"
                dst_folder = os.path.join(TARGET_DIR, rel_dir)
                dst_path = os.path.join(dst_folder, dst_fname)
                tasks.append((src_path, dst_folder, dst_path))
    return tasks

def convert_one(task):
    src_path, dst_folder, dst_path = task
    os.makedirs(dst_folder, exist_ok=True)
    if os.path.exists(dst_path) and os.path.getsize(dst_path) > 0:
        return (True, "skipped")
    
    cmd = [
        "ffmpeg",
        "-y",
        "-i", src_path,
        "-f", "apng",
        "-plays", "0",
        "-compression_level", "4",
        dst_path
    ]
    res = subprocess.run(cmd, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    if res.returncode == 0 and os.path.exists(dst_path) and os.path.getsize(dst_path) > 0:
        return (True, "converted")
    return (False, f"failed: {res.returncode}")

def main():
    tasks = get_file_list()
    total = len(tasks)
    print(f"Total files to process: {total}")
    start_time = time.time()
    
    completed = 0
    errors = []
    
    # Using 2 workers to match 2 available CPU cores
    with ThreadPoolExecutor(max_workers=2) as executor:
        for idx, (ok, status) in enumerate(executor.map(convert_one, tasks), 1):
            if not ok:
                errors.append((tasks[idx - 1][0], status))
            completed += 1
            if completed % 25 == 0 or completed == total:
                elapsed = time.time() - start_time
                avg = elapsed / completed if completed > 0 else 0
                remaining = avg * (total - completed)
                print(f"Progress: [{completed}/{total}] ({completed*100/total:.1f}%) | "
                      f"Elapsed: {elapsed:.1f}s | Est. remaining: {remaining:.1f}s")
                sys.stdout.flush()

    total_time = time.time() - start_time
    print(f"\nDone in {total_time:.1f}s!")
    if errors:
        print(f"Errors encountered ({len(errors)}):")
        for err in errors[:10]:
            print(f"  {err[0]}: {err[1]}")
    else:
        print("All files converted successfully without errors.")

if __name__ == "__main__":
    main()
