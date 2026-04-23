#!/system/bin/sh
# MiMo Tool: Document Processing (Excel/Word/PPTX)
# 用法: document.sh <action> <type> <file> [args...]

ACTION="$1"
DOC_TYPE="$2"
FILE="$3"
shift 3
ARGS="$*"

PYTHON=$(command -v python3 || command -v python)

check_python() {
    if [ -z "$PYTHON" ]; then
        echo "错误: 需要 Python"
        echo "安装: pkg install python"
        exit 1
    fi
}

case "$DOC_TYPE" in
    excel|xlsx)
        check_python
        case "$ACTION" in
            create)
                $PYTHON << 'PYEOF'
import sys
try:
    import openpyxl
except ImportError:
    import subprocess
    subprocess.run([sys.executable, '-m', 'pip', 'install', 'openpyxl', '-q'])
    import openpyxl

wb = openpyxl.Workbook()
ws = wb.active
ws.title = "Sheet1"

# 从参数读取数据
data = sys.argv[1] if len(sys.argv) > 1 else ""
if data:
    for i, row in enumerate(data.split(";")):
        for j, cell in enumerate(row.split(",")):
            ws.cell(row=i+1, column=j+1, value=cell.strip())

wb.save(sys.argv[2] if len(sys.argv) > 2 else "output.xlsx")
print(f"✓ Excel 已创建: {sys.argv[2] if len(sys.argv) > 2 else 'output.xlsx'}")
PYEOF
                ;;
            read)
                $PYTHON << 'PYEOF'
import sys
try:
    import openpyxl
except ImportError:
    print("错误: 需要 openpyxl")
    sys.exit(1)

wb = openpyxl.load_workbook(sys.argv[1])
for sheet in wb.sheetnames:
    ws = wb[sheet]
    print(f"\n=== {sheet} ===")
    for row in ws.iter_rows(values_only=True):
        print("\t".join(str(cell) if cell else "" for cell in row))
PYEOF
                ;;
            edit)
                echo "用法: document.sh edit excel <file> <row> <col> <value>"
                ;;
        esac
        ;;
    
    word|docx)
        check_python
        case "$ACTION" in
            create)
                $PYTHON << 'PYEOF'
import sys
try:
    from docx import Document
except ImportError:
    import subprocess
    subprocess.run([sys.executable, '-m', 'pip', 'install', 'python-docx', '-q'])
    from docx import Document

doc = Document()
content = sys.argv[1] if len(sys.argv) > 1 else "新文档"

for para in content.split("\\n"):
    if para.startswith("# "):
        doc.add_heading(para[2:], level=1)
    elif para.startswith("## "):
        doc.add_heading(para[3:], level=2)
    elif para.startswith("- "):
        doc.add_paragraph(para[2:], style='List Bullet')
    else:
        doc.add_paragraph(para)

output = sys.argv[2] if len(sys.argv) > 2 else "output.docx"
doc.save(output)
print(f"✓ Word 已创建: {output}")
PYEOF
                ;;
            read)
                $PYTHON << 'PYEOF'
import sys
try:
    from docx import Document
except ImportError:
    print("错误: 需要 python-docx")
    sys.exit(1)

doc = Document(sys.argv[1])
for para in doc.paragraphs:
    print(para.text)
PYEOF
                ;;
        esac
        ;;
    
    pptx|powerpoint)
        check_python
        case "$ACTION" in
            create)
                $PYTHON << 'PYEOF'
import sys
try:
    from pptx import Presentation
except ImportError:
    import subprocess
    subprocess.run([sys.executable, '-m', 'pip', 'install', 'python-pptx', '-q'])
    from pptx import Presentation

prs = Presentation()
content = sys.argv[1] if len(sys.argv) > 1 else "新演示文稿"

for slide_content in content.split("==="):
    slide = prs.slides.add_slide(prs.slide_layouts[1])
    lines = slide_content.strip().split("\\n")
    if lines:
        slide.shapes.title.text = lines[0]
        if len(lines) > 1:
            slide.placeholders[1].text = "\\n".join(lines[1:])

output = sys.argv[2] if len(sys.argv) > 2 else "output.pptx"
prs.save(output)
print(f"✓ PPTX 已创建: {output}")
PYEOF
                ;;
            read)
                $PYTHON << 'PYEOF'
import sys
try:
    from pptx import Presentation
except ImportError:
    print("错误: 需要 python-pptx")
    sys.exit(1)

prs = Presentation(sys.argv[1])
for i, slide in enumerate(prs.slides, 1):
    print(f"\n=== 幻灯片 {i} ===")
    for shape in slide.shapes:
        if hasattr(shape, "text"):
            print(shape.text)
PYEOF
                ;;
        esac
        ;;
    
    pdf)
        case "$ACTION" in
            read)
                if command -v pdftotext > /dev/null 2>&1; then
                    pdftotext "$FILE" -
                else
                    echo "错误: 需要 pdftotext"
                    echo "安装: pkg install poppler"
                fi
                ;;
            info)
                if command -v pdfinfo > /dev/null 2>&1; then
                    pdfinfo "$FILE"
                fi
                ;;
        esac
        ;;
    
    csv)
        case "$ACTION" in
            read)
                head -n "${ARGS:-50}" "$FILE"
                ;;
            analyze)
                check_python
                $PYTHON << 'PYEOF'
import sys
import csv

with open(sys.argv[1], 'r') as f:
    reader = csv.reader(f)
    rows = list(reader)
    
print(f"行数: {len(rows)}")
print(f"列数: {len(rows[0]) if rows else 0}")
print(f"\n前5行:")
for row in rows[:5]:
    print("\t".join(row))
PYEOF
                ;;
        esac
        ;;
    
    *)
        echo "用法: document.sh <action> <type> <file> [args]"
        echo "Types: excel, word, pptx, pdf, csv"
        echo "Actions: create, read, edit, analyze"
        exit 1
        ;;
esac
