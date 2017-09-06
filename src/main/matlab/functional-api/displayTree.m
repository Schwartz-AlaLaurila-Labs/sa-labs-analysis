function displayTree(treeBuilder)

import uiextras.jTree.*
f = figure();
t = Tree('Parent',f);

analysisTree = treeBuilder.getStructure();

parent = TreeNode('Name', analysisTree.get(1), 'Parent', t.Root);
id = 1;
parent.expand();

build(id, parent);

    function build(id, node)
        childs = analysisTree.getchildren(id);
        for i =  1 : numel(childs)
            import uiextras.jTree.*
            child = childs(i);
            if analysisTree.isleaf(child)
                TreeNode('Name', analysisTree.get(child), 'Parent', node);
                node.expand();
            else
                childNode = TreeNode('Name', analysisTree.get(child), 'Parent', node);
                node.expand();
                build(child, childNode);
            end
        end
    end

end



