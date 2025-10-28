"""
Setup script for Hongsa Drilling Data Processing Package
"""

from setuptools import setup, find_packages

with open("README.md", "r", encoding="utf-8") as fh:
    long_description = fh.read()

with open("requirements.txt", "r", encoding="utf-8") as fh:
    requirements = [line.strip() for line in fh if line.strip() and not line.startswith("#")]

setup(
    name="hongsa-drilling-data",
    version="1.0.0",
    author="Hongsa Project Team",
    author_email="team@hongsa.com",
    description="Data processing package for Hongsa drilling data",
    long_description=long_description,
    long_description_content_type="text/markdown",
    url="https://github.com/hongsa/drilling-data",
    packages=find_packages(),
    classifiers=[
        "Development Status :: 4 - Beta",
        "Intended Audience :: Developers",
        "License :: OSI Approved :: MIT License",
        "Operating System :: OS Independent",
        "Programming Language :: Python :: 3",
        "Programming Language :: Python :: 3.8",
        "Programming Language :: Python :: 3.9",
        "Programming Language :: Python :: 3.10",
        "Programming Language :: Python :: 3.11",
    ],
    python_requires=">=3.8",
    install_requires=requirements,
    extras_require={
        "dev": [
            "pytest>=6.0",
            "pytest-cov>=2.0",
            "black>=21.0",
            "flake8>=3.8",
            "mypy>=0.800",
        ],
    },
    entry_points={
        "console_scripts": [
            "hongsa-export=src.data_processing.export_sqlite_to_csv:main",
            "hongsa-clean=src.data_processing.clean_and_create_db:main",
            "hongsa-validate=src.data_processing.validate_database:main",
        ],
    },
)

