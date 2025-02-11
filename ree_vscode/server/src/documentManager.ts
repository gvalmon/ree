import { TextDocuments, Connection, TextDocumentIdentifier } from 'vscode-languageserver'
import { TextDocument } from 'vscode-languageserver-textdocument'
import { Subject } from 'rxjs'
import { forest } from './forest'

export enum DocumentEventKind {
	OPEN,
	CHANGE_CONTENT,
	CLOSE,
}

export interface DocumentEvent {
	kind: DocumentEventKind
	document: TextDocument
}

export default class DocumentManager {
	private readonly documents: TextDocuments<TextDocument>

	constructor() {
		this.documents = new TextDocuments(TextDocument)

		this.documents.onDidOpen((e) => {
			forest.createTree(e.document.uri, e.document.getText())
		})

		this.documents.onDidChangeContent((e) => {
			forest.updateTree(e.document.uri, e.document.getText())
		})

		this.documents.onDidClose((e) => {
			forest.deleteTree(e.document.uri)
		})
	}

	public get(id: TextDocumentIdentifier | string): TextDocument {
		const docId = typeof id === 'string' ? id : id.uri
		return this.documents.get(docId)!
	}

	public listen(connection: Connection): void {
		this.documents.listen(connection)
	}
}

export const documents = new DocumentManager()
