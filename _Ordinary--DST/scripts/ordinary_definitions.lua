-- Shared item definitions; prefab IDs stay stable across display-name changes.
return {
    {
        name = "roomcar_tattered_hat_base", zh = "破帽基", en = "Tattered Hat Base",
        recipe_zh = "一块能戴在头上的帽基。", recipe_en = "A simple base for a hat.",
        describe_zh = "一块朴素的帽基。", describe_en = "A plain hat base.",
        ingredients = {{"cutgrass", 2}},
    },
    {
        name = "roomcar_tattered_hat_mesh", zh = "破帽网", en = "Tattered Hat Net",
        recipe_zh = "一层疏疏的帽网。", recipe_en = "An open net for a hat.",
        describe_zh = "这张网倒是挺透气。", describe_en = "At least it is airy.",
        ingredients = {{"cutgrass", 2}},
    },
    {
        name = "roomcar_tattered_hat", zh = "破帽子", en = "Tattered Hat",
        recipe_zh = "帽基加上帽网，也算一顶帽子。", recipe_en = "A base and a net make a hat.",
        describe_zh = "一顶普通的破帽子。", describe_en = "An ordinary tattered hat.",
        ingredients = {{"roomcar_tattered_hat_base", 1}, {"roomcar_tattered_hat_mesh", 1}},
    },
    {
        name = "roomcar_plain_circlet", zh = "普通头环", en = "Plain Circlet",
        open_top = true,
        recipe_zh = "把绳索编成一件简单的头饰。", recipe_en = "A simple ornament woven from rope.",
        describe_zh = "一只朴素的编绳头环。", describe_en = "A plain braided circlet.",
        ingredients = {{"rope", 1}},
    },
}
