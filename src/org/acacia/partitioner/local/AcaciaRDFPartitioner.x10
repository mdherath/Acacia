/**
Copyright 2015 Acacia Team

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
 */

package org.acacia.partitioner.local;

import x10.io.File;
import x10.util.HashMap;
import x10.util.HashSet;
import org.acacia.util.Utils;
import java.util.LinkedList;

import com.hp.hpl.jena.rdf.model.Model;
import com.hp.hpl.jena.rdf.model.ModelFactory;
import com.hp.hpl.jena.util.FileManager;
import com.hp.hpl.jena.rdf.model.StmtIterator;
import com.hp.hpl.jena.rdf.model.Statement;
import com.hp.hpl.jena.rdf.model.Resource;
import com.hp.hpl.jena.rdf.model.Property;
import com.hp.hpl.jena.rdf.model.RDFNode;
import x10.util.ListIterator;

/**
 * Class AcaciaRDFPartitioner
 */
public class AcaciaRDFPartitioner {
    /**
     * Default constructor 
     */
	private var nodes:HashMap[Long,String] = new HashMap[Long,String]();
	private var predicates:HashMap[Long,String] = new HashMap[Long,String]();
	private var relationsMap:HashMap[Long,HashMap[Long,LinkedList]] = new HashMap[Long,HashMap[Long,LinkedList]]();
 	private var attributeMap:HashMap[Long,HashMap[Long,LinkedList]] = new HashMap[Long,HashMap[Long,LinkedList]]();

	private val ATTRIBUTE_GENRE 	= "Attribute";
	private val RELATIONSHIP_GENRE 	= "Relationship";

 	private val location = Utils.call_getAcaciaProperty("org.acacia.server.runtime.location")+"/rdfFiles/";
 	private val edgeListPath = location+"edgeList.dl";
 
    public def this() {
    	val f = new File(location);
    	if(!f.exists()){
    		f.mkdir();
    	}
    }
    
    public def readFile(val inputFile:String):void{
		// create poniter to edgeList file
    	val edgeList = new File(edgeListPath);
    	val printer = edgeList.printer();
    
    	// create an empty model
    	Console.OUT.println("creating model");
    	var model:Model = ModelFactory.createDefaultModel();
    	Console.OUT.println("model created");
        var fis:java.io.FileInputStream = null;
        try{
        	fis = new java.io.FileInputStream(new java.io.File(inputFile));
        }catch(val e:java.io.FileNotFoundException){
            e.printStackTrace();
        }
    	// read the RDF/XML file
		model.read(fis, null, "RDF/XML");
 		Console.OUT.println("model created2");
		iter:StmtIterator = model.listStatements();
 		Console.OUT.println("model created3");
	 	while (iter.hasNext()) {
	 		stmt:Statement		= iter.nextStatement();  // get next statement
	 	    subject:Resource   	= stmt.getSubject();     // get the subject
	 	    predicate:Property 	= stmt.getPredicate();   // get the predicate
	 	    object:RDFNode    	= stmt.getObject();      // get the object
	 	    
	 	    //Console.OUT.println("Subject : "+subject.toString());
	 	    var fromNode:Long = addToStore(nodes,subject.toString());
	 	    
	 	    //Console.OUT.println("Predicate : "+ predicate.toString() + " ");
	 	    var relation:Long = addToStore(predicates,predicate.toString());
	 	    
	 	    //Console.OUT.println("Object : "+object.toString());
	 	    var toNode:Long;
		    
	 	    if (object instanceof Resource) {
		    	toNode = addToStore(nodes,object.toString());
		    	addToMap(relationsMap,fromNode,relation,toNode);
		    	printer.println(fromNode+" "+toNode);
	 	    } else {
	 	    	// object is a literal
	 	    	addToMap(attributeMap,fromNode,relation,object.toString());
	 	    }
	 
		    //Console.OUT.println("------------------------------------------------------");
	 	}
	
	 	//flush the printer
	 	printer.flush();
	 
	 Console.OUT.println("model created4");
	 	writeStore(nodes,"nodeStore");
	 Console.OUT.println("model created5");
	 	writeStore(predicates,"predicateStore");
	 Console.OUT.println("model created6");
	 	writeMap(attributeMap,"attributeMap");
	 Console.OUT.println("model created7");
	 	writeMap(relationsMap,"relationMap");
	 Console.OUT.println("model created8");
    }
    
    private def addToStore(val map:HashMap[Long,String],val URI:String):Long{
    	var itr:Iterator[x10.util.Map.Entry[Long,String]] = map.entries().iterator();
    	while(itr.hasNext()){
    		val propItem:x10.util.Map.Entry[Long,String] = itr.next();
    		if(propItem.getValue().equals(URI)){
    			return propItem.getKey();
    		}
    	}
    	val id = map.size();
    	map.put(id,URI);
    
    	return id;
    }
    
    private def addToMap(val map:HashMap[Long,HashMap[Long,LinkedList]],val vertex:Long,val relation:Long,val value:Any):void{
    	var miniMap:HashMap[Long,LinkedList] = map.get(vertex);
    	Console.OUT.println(value);
    	if(miniMap != null){
    		var list:LinkedList = miniMap.get(relation);
    		if(list != null){
    			list.addLast(value);
    		}
    		else{
    			list = new LinkedList();
    			list.addLast(value);
    			miniMap.put(relation,list);
    		}
    	}
    	else{
    		var list:LinkedList = new LinkedList();
    		list.addLast(value);
    		miniMap = new HashMap[Long,LinkedList]();
    		miniMap.put(relation,list);
    		map.put(vertex,miniMap);
    	}
    }
    
    public def writeStore(val map:HashMap[Long,String],val fileName:String):void{
    	Console.OUT.println("*****"+fileName+"*****");
    	val O = new File(location+fileName);
    	val P = O.printer();
     	var itr:Iterator[x10.util.Map.Entry[Long,String]] = map.entries().iterator();
    	while(itr.hasNext()){
    		val attributeItem:x10.util.Map.Entry[Long,String] = itr.next();
    	    	//Console.OUT.println(attributeItem.getKey()+" "+attributeItem.getValue());
    	    	P.println(attributeItem.getKey()+" "+attributeItem.getValue());
    	}
   	    P.flush();
    }
    
    public def writeMap(val map:HashMap[Long,HashMap[Long,LinkedList]],val fileName:String):void{
    	Console.OUT.println("*****"+fileName+"*****");
    	val O = new File(location+fileName);
    	val P = O.printer();
    	val itr:Iterator[x10.util.Map.Entry[Long,HashMap[Long,LinkedList]]] = map.entries().iterator();
    	while(itr.hasNext()){
    		val mapItem:x10.util.Map.Entry[Long,HashMap[Long,LinkedList]] = itr.next();
    		val itr2:Iterator[x10.util.Map.Entry[Long,LinkedList]] = mapItem.getValue().entries().iterator();
    		while(itr2.hasNext()){
    			val miniMapItem:x10.util.Map.Entry[Long,LinkedList] = itr2.next();
    			val itr3:java.util.ListIterator = miniMapItem.getValue().listIterator();
    			//Console.OUT.print(mapItem.getKey()+" "+miniMapItem.getKey());
    			P.print(mapItem.getKey()+" "+miniMapItem.getKey());
    			while(itr3.hasNext()){
    				val value = itr3.next();
    				//Console.OUT.print(" "+value);
    				P.print(" "+value);
    			}
    			//Console.OUT.println();
    			P.println();
    		}
    		
    	}
    	P.flush();
    }
    
    public def getEdgeList():String{
    	return edgeListPath;
    }
}