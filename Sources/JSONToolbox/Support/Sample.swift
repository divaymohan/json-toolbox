import Foundation

/// Sample documents so the app is useful the moment it launches.
enum Sample {
    static let pretty = """
    {
      "name": "JSON Toolbox",
      "version": 1,
      "lightweight": true,
      "features": ["beautify", "compare", "edit", "tree"],
      "author": {
        "name": "You",
        "email": "developer@itspaydai.com"
      },
      "shortcuts": null
    }
    """

    static let left = """
    {
      "name": "JSON Toolbox",
      "version": 1,
      "features": ["beautify", "compare", "edit"],
      "beta": true
    }
    """

    static let right = """
    {
      "name": "JSON Toolbox",
      "version": 2,
      "features": ["beautify", "compare", "edit", "tree"],
      "author": "You"
    }
    """
}
