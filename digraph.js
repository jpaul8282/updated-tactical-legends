digraph TacticalLegends {
    // Overall settings
    rankdir=TB;
    node [shape=box, style=rounded, fontname="Helvetica"];
    edge [fontname="Helvetica"];

    // --- Clusters / subsystems ---

    subgraph cluster_core {
        label="Core Engine";
        style=filled;
        color=lightblue;
        CoreEngine [label="Core Engine\n(C++ / SDL2)"];
        GameLoop [label="Game Loop", style=filled, fillcolor=lightgreen];
    }

    subgraph cluster_ai {
        label="AI Modules";
        style=filled;
        color=wheat;
        EnemyAI [label="Enemy AI"];
        StealthCombatAI [label="Stealth & Combat AI"];
        // Add more AI modules here based on your repo
    }

    CampaignManager [label="Campaign Manager", style=filled, fillcolor=lightyellow];

    AudioManager [label="Audio Manager", style=filled, fillcolor=lightyellow];

    subgraph cluster_ui {
        label="UI Layer";
        style=filled;
        color=plum;
        CodexPanel [label="CodexPanel.vue"];
        MissionUIManager [label="Mission UI Manager"];
        // Add other UI components here
    }

    subgraph cluster_data {
        label="Data Layer";
        style=filled;
        color=lightcoral;
        Prisma [label="Prisma DB"];
        JSONConfigs [label="JSON Configs"];
        // Add other data / storage components here
    }

    subgraph cluster_build {
        label="Deployment & Build";
        style=filled;
        color=lightgray;
        CMake [label="CMake"];
        YAMLWorkflows [label="YAML Workflows"];
    }

    CTest [label="CTest (Testing)", style=filled, fillcolor=lightsteelblue];

    // --- Arrows / Dependencies ---

    GameLoop -> CoreEngine;

    CoreEngine -> EnemyAI;
    CoreEngine -> StealthCombatAI;
    CoreEngine -> CampaignManager;
    CoreEngine -> AudioManager;

    CampaignManager -> CodexPanel;
    CampaignManager -> MissionUIManager;
    CampaignManager -> Prisma;
    CampaignManager -> JSONConfigs;

    YAMLWorkflows -> CTest;
    CMake -> YAMLWorkflows;

    // Optional: UI → Data (if UI uses data)
    CodexPanel -> JSONConfigs;
    MissionUIManager -> Prisma;
}
