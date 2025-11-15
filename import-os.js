import os

# --- CONFIGURATION ---
repo_path = "/path/to/your/tactical-legends"  # <-- Change to your local repo path
output_dot = "tactical_legends_auto.dot"

# --- Helper functions ---
def escape_label(name):
    return name.replace("_", "\\_")

def scan_folder(path, parent_name=None):
    """
    Recursively scans a folder and returns Graphviz nodes & subgraphs.
    """
    entries = [e for e in os.listdir(path) if not e.startswith('.')]
    folders = [e for e in entries if os.path.isdir(os.path.join(path, e))]
    files = [e for e in entries if os.path.isfile(os.path.join(path, e))]

    lines = []

    # Create cluster for this folder
    cluster_name = parent_name or os.path.basename(path)
    lines.append(f'subgraph cluster_{cluster_name} {{')
    lines.append(f'    label="{escape_label(cluster_name)}";')
    lines.append('    style=filled;')
    lines.append('    color=lightgray;')

    # Add files as nodes
    for f in files:
        node_name = f"{cluster_name}_{f}".replace('.', '_')
        lines.append(f'    {node_name} [label="{escape_label(f)}"];')

    # Recursively add subfolders
    for folder in folders:
        sub_path = os.path.join(path, folder)
        sub_lines = scan_folder(sub_path, parent_name=f"{cluster_name}_{folder}")
        lines.extend(['    ' + line for line in sub_lines])

    lines.append('}')
    return lines

# --- Generate DOT file ---
dot_lines = [
    'digraph TacticalLegends {',
    '    rankdir=TB;',
    '    node [shape=box, style=rounded, fontname="Helvetica"];',
    '    edge [fontname="Helvetica"];'
]

dot_lines.extend(scan_folder(repo_path))

# Optional: basic arrows from parent folder → subfolder/file
# (This is a simple heuristic; you can refine arrows manually later)
# Example: link cluster to its immediate children
# (Could add later if needed)

dot_lines.append('}')
dot_content = '\n'.join(dot_lines)

with open(output_dot, 'w') as f:
    f.write(dot_content)

print(f"Graphviz DOT file generated: {output_dot}")
print("You can render it using: dot -Tpng tactical_legends_auto.dot -o arch.png")
import os

# --- CONFIGURATION ---
repo_path = "/path/to/your/tactical-legends"  # <-- Change to your local repo path
output_dot = "tactical_legends_auto_colored.dot"

# Map folder keywords to colors and module types
module_colors = {
    'core': ('lightblue', 'Core Engine'),
    'engine': ('lightblue', 'Core Engine'),
    'ai': ('wheat', 'AI Module'),
    'campaign': ('lightyellow', 'Campaign Manager'),
    'audio': ('lightyellow', 'Audio Manager'),
    'ui': ('plum', 'UI Layer'),
    'data': ('lightcoral', 'Data Layer'),
    'prisma': ('lightcoral', 'Data Layer'),
    'build': ('lightgray', 'Build/Deployment'),
    'cmake': ('lightgray', 'Build/Deployment'),
    'tests': ('lightsteelblue', 'Testing'),
    'test': ('lightsteelblue', 'Testing'),
}

# --- Helper functions ---
def escape_label(name):
    return name.replace("_", "\\_")

def get_color(folder_name):
    folder_name_lower = folder_name.lower()
    for key, (color, _) in module_colors.items():
        if key in folder_name_lower:
            return color
    return 'white'  # default

def scan_folder(path, parent_name=None):
    """
    Recursively scans a folder and returns Graphviz nodes & subgraphs.
    """
    entries = [e for e in os.listdir(path) if not e.startswith('.')]
    folders = [e for e in entries if os.path.isdir(os.path.join(path, e))]
    files = [e for e in entries if os.path.isfile(os.path.join(path, e))]

    lines = []

    # Determine cluster name & color
    cluster_name = parent_name or os.path.basename(path)
    cluster_color = get_color(os.path.basename(path))

    lines.append(f'subgraph cluster_{cluster_name} {{')
    lines.append(f'    label="{escape_label(os.path.basename(path))}";')
    lines.append(f'    style=filled;')
    lines.append(f'    color={cluster_color};')

    # Add files as nodes
    for f in files:
        node_name = f"{cluster_name}_{f}".replace('.', '_')
        lines.append(f'    {node_name} [label="{escape_label(f)}"];')

    # Recursively add subfolders
    for folder in folders:
        sub_path = os.path.join(path, folder)
        sub_lines = scan_folder(sub_path, parent_name=f"{cluster_name}_{folder}")
        lines.extend(['    ' + line for line in sub_lines])

    lines.append('}')
    return lines

# --- Generate DOT file ---
dot_lines = [
    'digraph TacticalLegends {',
    '    rankdir=TB;',
    '    node [shape=box, style=rounded, fontname="Helvetica"];',
    '    edge [fontname="Helvetica"];'
]

dot_lines.extend(scan_folder(repo_path))

dot_lines.append('}')
dot_content = '\n'.join(dot_lines)

with open(output_dot, 'w') as f:
    f.write(dot_content)

print(f"Graphviz DOT file with colored clusters generated: {output_dot}")
print("Render it using: dot -Tpng tactical_legends_auto_colored.dot -o arch_colored.png")
