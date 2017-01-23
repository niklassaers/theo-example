import UIKit
import Theo

class QueryViewController: UIViewController {

    var connectionConfig: ConnectionConfig?
    @IBOutlet weak var outputTextView: UITextView?
    
    @IBOutlet weak var createNodeButton: UIButton?
    @IBOutlet weak var fetchNodeButton: UIButton?
    @IBOutlet weak var runCypherButton: UIButton?
    @IBOutlet weak var runTransactionButton: UIButton?
    
    
    private var theo: Theo.Client?
    private var lastNodeId = "1"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        disableButtons()
        if let config = connectionConfig {
            theo = Client(baseURL: config.host, user: config.username, pass: config.password)
            outputTextView?.text = "Connecting..."
            theo?.metaDescription({ [weak self] (_, error) in
                DispatchQueue.main.async { [weak self] in
                    if let error = error {
                        self?.outputTextView?.text = "Error while connecting: \(error)"
                    } else {
                        self?.outputTextView?.text = "Connected"
                        self?.enableButtons()
                    }
                }
            })
        } else {
            outputTextView?.text = "Missing connection configuration"
        }

    }

    private func enableButtons() {
        createNodeButton?.isEnabled = true
        fetchNodeButton?.isEnabled = true
        runCypherButton?.isEnabled = true
        runTransactionButton?.isEnabled = true
    }
    
    private func disableButtons() {
        createNodeButton?.isEnabled = false
        fetchNodeButton?.isEnabled = false
        runCypherButton?.isEnabled = false
        runTransactionButton?.isEnabled = false
    }
    
    @IBAction func createNodeTapped(_ sender: UIButton) {
        let node = Node()
        let randomString: String = UUID().uuidString
        
        node.addLabel("TheoTest")
        node.setProp("propertyKey_1", propertyValue: "propertyValue_1" + randomString)
        node.setProp("propertyKey_2", propertyValue: "propertyValue_2" + randomString)
        
        theo?.createNode(node, completionBlock: { (node, error) in
            DispatchQueue.main.async { [weak self] in
                let text = self?.outputTextView?.text ?? ""
                if let error = error {
                    self?.outputTextView?.text = "Error while creating node: \(error)\n\n\(text)"
                } else {
                    let nodeId = node?.meta?.nodeID()
                    self?.outputTextView?.text = "Created node with ID \(nodeId ?? "N/A")\n\n\(text)"
                    if let nodeId = nodeId {
                        self?.lastNodeId = nodeId
                    }
                }
            }
        })

    }
    
    @IBAction func fetchNodeTapped(_ sender: UIButton) {
        let fetchingId = lastNodeId
        theo?.fetchNode(fetchingId, completionBlock: { (node, error) in
            DispatchQueue.main.async { [weak self] in
                let text = self?.outputTextView?.text ?? ""
                if let error = error {
                    self?.outputTextView?.text = "Error while fetching node with ID '\(fetchingId)': \(error)\n\n\(text)"
                } else {
                    self?.outputTextView?.text = "Fetched node with ID \(node?.meta?.nodeID() ?? "N/A") successfully\n\n\(text)"
                }
            }
        })

    }
    
    @IBAction func runCypherTapped(_ sender: UIButton) {
        theo?.executeCypher("MATCH (n:TheoTest) RETURN count(n) AS num") { (result, error) in
            DispatchQueue.main.async { [weak self] in
                let text = self?.outputTextView?.text ?? ""
                if let error = error {
                    self?.outputTextView?.text = "Error while executing cypher: \(error)\n\n\(text)"
                } else {
                    var num = "N/A"
                    if let data = result?.data,
                        let n = data.first?["num"] as? Int {
                        num = "\(n)"
                    }
                    self?.outputTextView?.text = "Asked via Cypher how many nodes there are with label TheoTest. Answer: \(num)\n\n\(text)"
                }
            }
        }
    }
    
    @IBAction func runTransactionTapped(_ sender: UIButton) {
        let statement1 = [
            "statement" : "CREATE (n:TheoTest { myProperty: 'A value' } )" as AnyObject,
            "resultDataContents" : ["graph","row"] as AnyObject
        ]
        let statement2 = [
            "statement" : "CREATE (m:TheoTest { myProperty: 'Another value' } )" as AnyObject,
            "resultDataContents" : ["graph","row"] as AnyObject
        ]
        
        theo?.executeTransaction([statement1, statement2]) { (result, error) in
            DispatchQueue.main.async { [weak self] in
                let text = self?.outputTextView?.text ?? ""
                if let error = error {
                    self?.outputTextView?.text = "Error while executing transaction: \(error)\n\n\(text)"
                } else {
                    self?.outputTextView?.text = "Transaction completed successfully\n\n\(text)"
                }
            }
        }
        
    }
    
}
