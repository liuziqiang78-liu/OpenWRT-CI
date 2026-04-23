#!/system/bin/sh
# MiMo Tool: Data Science
# 用法: datascience.sh <action> <file> [args...]

ACTION="$1"
FILE="$2"
shift 2
ARGS="$*"

MIMO_API="http://localhost:8080"
PYTHON=$(command -v python3 || command -v python)

check_python() {
    if [ -z "$PYTHON" ]; then
        echo "错误: 需要 Python"
        exit 1
    fi
}

case "$ACTION" in
    analyze|eda)
        check_python
        echo "📊 数据分析: $FILE"
        echo "---"
        
        $PYTHON << PYEOF
import sys
import json

try:
    import pandas as pd
except ImportError:
    import subprocess
    subprocess.run([sys.executable, '-m', 'pip', 'install', 'pandas', '-q'])
    import pandas as pd

# 读取数据
if "$FILE".endswith('.csv'):
    df = pd.read_csv("$FILE")
elif "$FILE".endswith('.xlsx'):
    df = pd.read_excel("$FILE")
elif "$FILE".endswith('.json'):
    df = pd.read_json("$FILE")
else:
    df = pd.read_csv("$FILE")

print("=== 数据概览 ===")
print(f"行数: {df.shape[0]}, 列数: {df.shape[1]}")
print(f"\n=== 列信息 ===")
print(df.dtypes)
print(f"\n=== 统计摘要 ===")
print(df.describe())
print(f"\n=== 缺失值 ===")
print(df.isnull().sum())
print(f"\n=== 前5行 ===")
print(df.head())
PYEOF
        ;;
    
    profile)
        check_python
        echo "📋 数据画像: $FILE"
        echo "---"
        
        $PYTHON << PYEOF
try:
    import pandas as pd
    from pandas_profiling import ProfileReport
except ImportError:
    import subprocess
    import sys
    subprocess.run([sys.executable, '-m', 'pip', 'install', 'pandas', 'ydata-profiling', '-q'])
    import pandas as pd
    from pandas_profiling import ProfileReport

df = pd.read_csv("$FILE")
profile = ProfileReport(df, title="Data Profile", explorative=True)
profile.to_file("/data/adb/mimo/cache/profile.html")
print("✓ 数据画像已生成: /data/adb/mimo/cache/profile.html")
PYEOF
        ;;
    
    visualize|viz)
        check_python
        echo "📈 数据可视化: $FILE"
        echo "---"
        
        $PYTHON << PYEOF
try:
    import pandas as pd
    import matplotlib
    matplotlib.use('Agg')
    import matplotlib.pyplot as plt
except ImportError:
    import subprocess
    import sys
    subprocess.run([sys.executable, '-m', 'pip', 'install', 'pandas', 'matplotlib', '-q'])
    import pandas as pd
    import matplotlib
    matplotlib.use('Agg')
    import matplotlib.pyplot as plt

df = pd.read_csv("$FILE")

# 自动生成图表
fig, axes = plt.subplots(2, 2, figsize=(12, 10))

# 数值列直方图
num_cols = df.select_dtypes(include=['number']).columns[:4]
for i, col in enumerate(num_cols):
    ax = axes[i//2][i%2]
    df[col].hist(ax=ax, bins=30)
    ax.set_title(col)

plt.tight_layout()
plt.savefig('/data/adb/mimo/cache/viz.png', dpi=150)
print("✓ 可视化已保存: /data/adb/mimo/cache/viz.png")
PYEOF
        ;;
    
    model|train)
        check_python
        echo "🤖 建模: $FILE"
        echo "---"
        
        $PYTHON << PYEOF
try:
    import pandas as pd
    from sklearn.model_selection import train_test_split
    from sklearn.ensemble import RandomForestClassifier
    from sklearn.metrics import accuracy_score
except ImportError:
    import subprocess
    import sys
    subprocess.run([sys.executable, '-m', 'pip', 'install', 'pandas', 'scikit-learn', '-q'])
    import pandas as pd
    from sklearn.model_selection import train_test_split
    from sklearn.ensemble import RandomForestClassifier
    from sklearn.metrics import accuracy_score

df = pd.read_csv("$FILE")

# 自动选择目标列（最后一列）
target = df.columns[-1]
X = df.drop(columns=[target])
y = df[target]

# 处理分类变量
X = pd.get_dummies(X)

# 分割数据
X_train, X_test, y_train, y_test = train_test_split(X, y, test_size=0.2, random_state=42)

# 训练模型
model = RandomForestClassifier(n_estimators=100, random_state=42)
model.fit(X_train, y_train)

# 评估
y_pred = model.predict(X_test)
acc = accuracy_score(y_test, y_pred)

print(f"目标列: {target}")
print(f"准确率: {acc:.4f}")
print(f"\n特征重要性:")
for name, imp in sorted(zip(X.columns, model.feature_importances_), key=lambda x: -x[1])[:10]:
    print(f"  {name}: {imp:.4f}")
PYEOF
        ;;
    
    clean)
        check_python
        echo "🧹 数据清洗: $FILE"
        echo "---"
        
        $PYTHON << PYEOF
import pandas as pd

df = pd.read_csv("$FILE")
original_shape = df.shape

# 删除重复行
df = df.drop_duplicates()

# 填充缺失值
for col in df.columns:
    if df[col].dtype in ['int64', 'float64']:
        df[col] = df[col].fillna(df[col].median())
    else:
        df[col] = df[col].fillna(df[col].mode()[0] if not df[col].mode().empty else 'Unknown')

# 保存清洗后的数据
output = "$FILE".replace('.csv', '_cleaned.csv')
df.to_csv(output, index=False)

print(f"原始数据: {original_shape}")
print(f"清洗后: {df.shape}")
print(f"已保存: {output}")
PYEOF
        ;;
    
    *)
        echo "用法: datascience.sh <action> <file>"
        echo "Actions: analyze, profile, visualize, model, clean"
        exit 1
        ;;
esac
