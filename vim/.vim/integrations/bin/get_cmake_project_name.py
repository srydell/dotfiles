"""
Brief:               Try to fetch the name of the cmake project from the cwd and print it
                     If no project name can be parsed:
                         print the parent directory of the top level CMakeLists.txt
                     If no CMakeLists.txt is found:
                         print the current directory

File name:           get_cmake_project_name.py
Author:              Simon Rydell
Python Version:      3.7
"""

from pathlib import Path
import re


def get_top_level_cmakelists():
    """Return the path of the top level CMakeLists.txt if there is one
    :returns: Path or None on failure
    """
    project_file = "CMakeLists.txt"
    current_dir = Path.cwd()
    top_level_path = None

    # While we are not at the root directory
    while current_dir != current_dir.parent:
        # Check if there is a CMakeLists.txt in thir directory
        if Path.is_file(current_dir / project_file):
            top_level_path = current_dir / project_file

        # Go up one level
        current_dir = current_dir.parent

    return top_level_path


def get_project_name(cmake_file):
    """Parse cmake_file for project declaration:

        project(PROJECT_NAME VERSION 0.1 LANGUAGES CXX)

        If no project name found, return None

    :cmake_file: Path to cmake file
    :returns: String (project name) or None on failure
    """
    project_matcher = re.compile(r"^\s*project\((\w+).*")
    with open(cmake_file, "r") as project_file:
        for line in project_file.readlines():
            match = project_matcher.match(line)
            if match:
                return match.group(1)
    return None


def main():
    """Print the project name
    :returns: None
    """
    project_file = get_top_level_cmakelists()
    if project_file:
        project_name = get_project_name(project_file)
        if project_name:
            print(project_name)
        else:
            # The directory of the top level project file
            print(project_file.parent.stem)
    else:
        # The current directory if all else fails
        print(Path.cwd().stem)


if __name__ == "__main__":
    main()
