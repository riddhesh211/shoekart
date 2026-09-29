import os
from icrawler.builtin import BingImageCrawler

BASE_FOLDER = os.path.join("static", "images")

missing_images = {
    "sneakers": {
        1: "running sneakers shoes",
        12: "athletic sneakers shoes",
        13: "premium sneakers shoes"
    },
    "sandals": {
        12: "leather sandals men"
    }
}

for category, images in missing_images.items():

    category_folder = os.path.join(BASE_FOLDER, category)
    os.makedirs(category_folder, exist_ok=True)

    print("\n==============================")
    print("Downloading:", category.upper())
    print("==============================")

    for index, search_text in images.items():

        target = os.path.join(
            category_folder,
            f"{category}_{index}.jpg"
        )

        print(f"\n[{category}_{index}] Searching: {search_text}")

        crawler = BingImageCrawler(
            storage={"root_dir": category_folder}
        )

        try:
            crawler.crawl(
                keyword=search_text,
                max_num=1
            )

            files = os.listdir(category_folder)

            candidates = [
                os.path.join(category_folder, f)
                for f in files
                if f != os.path.basename(target)
                and os.path.isfile(os.path.join(category_folder, f))
            ]

            if candidates:
                latest_file = max(
                    candidates,
                    key=os.path.getctime
                )

                os.replace(latest_file, target)

                print("Saved:", target)
            else:
                print("Image not downloaded.")

        except Exception as e:
            print("ERROR:", e)

print("\n==============================")
print("DONE - Missing images checked")
print("==============================")