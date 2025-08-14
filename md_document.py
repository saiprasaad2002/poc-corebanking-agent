#convert a docx file to markdown
from docling.document_converter import DocumentConverter

def return_markdown(document_path: str) -> str:
    converter = DocumentConverter()
    result = converter.convert(document_path)
    markdown = result.document.export_to_markdown()
    return markdown
 