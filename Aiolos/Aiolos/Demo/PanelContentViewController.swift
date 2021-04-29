import Foundation
import UIKit

/// The ViewController that is displayed inside of the Panel
final class PanelContentViewController: UITableViewController {
    private let color: UIColor

    // MARK: - Lifecycle

    init(color: UIColor) {
        self.color = color
        super.init(style: .plain)
        self.title = "Content"
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - UIViewController

    override func viewDidLoad() {
        super.viewDidLoad()

        self.view.backgroundColor = self.color
        self.tableView.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self,
                                                                 action: #selector(handleAddPress))
    }
}

// MARK: - UITableViewDataSource

extension PanelContentViewController {
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        100
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        cell.textLabel?.text = "Cell \(indexPath.row)"
        cell.contentView.backgroundColor = .clear
        cell.backgroundView?.backgroundColor = .clear
        cell.backgroundColor = .clear
        return cell
    }

    override func tableView(_ tableView: UITableView,
                            editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        [UITableViewRowAction(style: .destructive, title: "Delete", handler: { _, _ in })]
    }
}

// MARK: - Private

private extension PanelContentViewController {
    @objc
    func handleAddPress(_ sender: UIBarButtonItem) {
        guard let panel = self.aiolosPanel else { return }

        print("+ was pressed")
        if panel.configuration.mode == .compact {
            panel.configuration.mode = .expanded
        }
    }
}
