import os
import requests
from icrawler.builtin import BingImageCrawler

# -----------------------------------------
# ShoeKart - Footwear Image Downloader
# -----------------------------------------

BASE_FOLDER = os.path.join("static", "images")

os.makedirs(BASE_FOLDER, exist_ok=True)


products = {
    "sneakers": [
        "running sneakers shoes",
        "casual sneakers shoes",
        "sports sneakers shoes",
        "men running shoes",
        "men casual sneakers",
        "white sneakers shoes",
        "black sports sneakers",
        "training sneakers shoes",
        "walking sneakers shoes",
        "fashion sneakers shoes",
        "comfortable sneakers shoes",
        "athletic sneakers shoes",
        "premium sneakers shoes"
    ],

    "sandals": [
        "men casual sandals",
        "men sports sandals",
        "comfortable sandals",
        "outdoor sandals",
        "walking sandals",
        "black sandals men",
        "brown sandals men",
        "travel sandals men",
        "daily wear sandals",
        "comfortable sports sandals",
        "formal sandals men",
        "leather sandals men",
        "premium sandals men"
    ],

    "chappals": [
        "men casual chappal",
        "men slippers",
        "men flip flop slippers",
        "daily wear chappal",
        "comfortable chappal men",
        "black slippers men",
        "brown slippers men",
        "home slippers men",
        "rubber slippers men",
        "casual slippers men",
        "comfortable flip flops men",
        "simple chappal men",
        "premium slippers men"
    ]
}


def download_images(category, searches):

    category_folder = os.path.join(BASE_FOLDER, category)
    os.makedirs(category_folder, exist_ok=True)

    print("\n================================")
    print("Downloading:", category.upper())
    print("================================")

    for index, search_text in enumerate(searches, start=1):

        filename = f"{category}_{index}"

        print(f"\n[{index}/13] Searching: {search_text}")

        crawler = BingImageCrawler(
            storage={
                "root_dir": category_folder
            }
        )

        try:
            crawler.crawl(
                keyword=search_text,
                max_num=1
            )

            # Rename downloaded image
            files = os.listdir(category_folder)

            if files:
                latest_file = max(
                    [
                        os.path.join(category_folder, f)
                        for f in files
                    ],
                    key=os.path.getctime
                )

                extension = os.path.splitext(latest_file)[1]

                new_file = os.path.join(
                    category_folder,
                    filename + extension
                )

                if latest_file != new_file:
                    os.rename(latest_file, new_file)

                print("Saved:", new_file)

        except Exception as e:
            print("ERROR:", e)


# Download all 39 images
for category, searches in products.items():
    download_images(category, searches)


print("\n================================")
print("DONE!")
print("39 footwear images downloaded.")
print("================================")