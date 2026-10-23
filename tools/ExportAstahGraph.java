import java.awt.geom.*;
import java.nio.file.*;
import java.util.*;
import com.change_vision.jude.api.inf.AstahAPI;
import com.change_vision.jude.api.inf.project.ProjectAccessor;
import com.change_vision.jude.api.inf.model.*;
import com.change_vision.jude.api.inf.presentation.*;
public class ExportAstahGraph {
 static String clean(String s){return s==null?"":s.replace('\t',' ').replace('\n',' ');}
 public static void main(String[] args) throws Exception {
  ProjectAccessor a=AstahAPI.getAstahAPI().getProjectAccessor();a.open(args[0]);
  List<String> rows=new ArrayList<String>();List<String> model=new ArrayList<String>();int index=0;
  try{
   for(INamedElement item:a.findElements(IDiagram.class)){
    IDiagram d=(IDiagram)item;rows.add("DIAGRAM\t"+index+"\t"+clean(d.getName()));
    for(IPresentation p:d.getPresentations()){
     if(p instanceof INodePresentation){INodePresentation n=(INodePresentation)p;Point2D q=n.getLocation();rows.add("N\t"+index+"\t"+p.getID()+"\t"+p.getType()+"\t"+clean(p.getLabel())+"\t"+q.getX()+"\t"+q.getY()+"\t"+n.getWidth()+"\t"+n.getHeight());}
     else if(p instanceof ILinkPresentation){ILinkPresentation l=(ILinkPresentation)p;String s="E\t"+index+"\t"+p.getID()+"\t"+p.getType()+"\t"+clean(p.getLabel())+"\t"+l.getSource().getID()+"\t"+l.getTarget().getID();for(Point2D q:l.getAllPoints())s+="\t"+q.getX()+","+q.getY();rows.add(s);
      IElement e=p.getModel();String m=p.getID()+"\t"+p.getType()+"\t"+e.getId();
      if(e instanceof IGeneralization){IGeneralization v=(IGeneralization)e;m+="\tsub="+v.getSubType().getId()+"\tsuper="+v.getSuperType().getId();}
      if(e instanceof IRealization){IRealization v=(IRealization)e;m+="\tclient="+v.getClient().getId()+"\tsupplier="+v.getSupplier().getId();}
      if(e instanceof IAssociation)for(IAttribute v:((IAssociation)e).getMemberEnds())m+="\tend="+v.getType().getId()+",composite="+v.isComposite()+",aggregate="+v.isAggregate();
      if(e instanceof IInclude){IInclude v=(IInclude)e;m+="\tincluding="+v.getIncludingCase().getId()+"\taddition="+v.getAddition().getId();}
      if(e instanceof IExtend){IExtend v=(IExtend)e;m+="\textension="+v.getExtension().getId()+"\textended="+v.getExtendedCase().getId();}
      m+="\tpresentation="+l.getSource().getModel().getId()+","+l.getTarget().getModel().getId();model.add(m);
     }
    }index++;
   }
   a.validateProject();Files.write(Paths.get(args[1]),rows);Collections.sort(model);Files.write(Paths.get(args[1]+".semantics"),model);
  }finally{a.close();}
 }
}
