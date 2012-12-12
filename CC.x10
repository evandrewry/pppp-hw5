import x10.util.concurrent.AtomicBoolean;
import x10.util.Timer;
import x10.util.Random; 


/**
 * The transition relation is defined by:
 *
 * (I)      {n(X) | S} --> {n(X,X) | S}
 *
 *
 *        n(X,C) in S   e(X,Y) in S   C < D
 * (II) -------------------------------------
 *       { n(Y,D) | S} --> {n(Y,C) | S}
 *
 *
 *        n(X,C) in S   e(Y,X) in S   C < D
 * (III) -------------------------------------
 *         { n(Y,D) | S} --> {n(Y,C) | S}
 *
 *
 * Q1: Suppose a configuration A represents a finite directed graph.
 * Can there be an infinite execution sequences starting from A. Why or
 * why not?  
 *
 * No, the execution will always halt because of the constraint that 
 * there cannot be duplicate atoms in a configuration. Therefore, the
 * execution sequence will always reach a point where it is not possible
 * to produce any additional atoms (and per the transition rules, the
 * number of atoms in a configuration increases monotonically during
 * execution, so we know that when we cannot add any more atoms to the
 * configuration we must be finished).
 *
 * Q2: Is this transition system determinate?  Why or why not?
 * 
 * Yes, the system is determinate because regardless of the order in which
 * the rules are applied they will "complete the diamond" and produce
 * identical terminal configurations.
 *
 * Q3: Let A be a configuration representing a graph and containing only
 * n(X) and e(X,Y) atoms. Let Z be a terminal configuration such that A
 * -->* Z. For each of the following assertions, specify which are true
 * or false. Justify.
 *
 * A. For every node n(X) in A, Z contains an atom n(X,C) for some C.
 *
 * This is false. As a simple counterexample, consider the case when A
 * contains only n(X) atoms and no e(X,Y) atoms. Z will contain only
 * the atoms in A as well as the atoms generated by rule (I), which 
 * are of the form n(X,X), so clearly there will be no node C that
 * satisfies n(X, C) for every X.
 *
 * B. If n(X,C) in Z then n(C) in A and n(X) in A, and X and C are
 * connected in A.
 *
 * This is true. The production rules recursively define an execution
 * in which it is impossible for n(X,C) to be produced if X and C are
 * unconnected. Rule (I) defines the base case, where all nodes are
 * connected to themselves - n(X, X). Rules (II) and (III) produce
 * n(X, Y) atoms from existing n(X, X) and n(X, Y) based on the edge
 * atoms that exist in A. Inductively, no n(X, C) can exist in Z if X
 * and C are not connected in A.
 *
 * C. For any node X in A, let C be the node in A connected to X s.t.
 * no node connected to X in A has lower id.  Then n(X,C) in Z.
 *
 * This is true. Production rules (II) and (III) produce all pairs
 * of connected nodes where the second node in the pair is of lower
 * id than the first. Therefore, when the execution sequence terminates,
 * the minimum value of Y for all n(X,Y) will be C.
 *
 * Q4: Provide the tightest upper bound you can for the run-time of the
 * algorithm, in terms of number of transitions, assuming the initial
 * graph has N nodes and E edges. (Do not go overboard, O(N^2) is
 * acceptable compared to O(N^1.73565), and O(log(N)) is acceptable 
 * compared to O(log(log(N))).)
 *
 * Q5: Implement the following method in X10 to compute the connected components
 * of a graph -- feel free to use whatever ideas you may have gleaned
 * from the questions above. Your code need run in only one place, but
 * should take advantage of multiple workers in the place. The runtime
 * will be tested for 1, 2, 4 and 8 workers on inputs with O(10^5)
 * vertices and O(10^9) edges.
 *
 * Each vertex in the graph is identified by a non-negative
 * id, ranging from 0 through N-1. The rails D and A are of size N.  On
 * entry into the procedure, D(i)=i, for all i. A specifies the adjacency
 * matrix for the graph -- for each i, A(i) is the rail of vertices
 * connected to i. The graph is undirected, so if j is in (the rail) A(i)
 * then it is the case that i will be in A(j).
 * 
 * On exit from the procedure D(i) should be the smallest id of vertices
 * in the graph that i is connected to (through an undirected path). 
 */

public class CC {
  static def cc(d:Rail[Int],a:Rail[Rail[Int]], size:Int, nworkers:Int) {
    val done = new AtomicBoolean(false);
    val step = (d.size < nworkers) ? 1 : (d.size / nworkers);
    while (!done.get()) {
      done.set(true);
      finish for (var lower:Int = 0; lower < d.size; lower += step){
        val l = lower;
        val u = (lower + step >= d.size) ? d.size : (lower + step);
        async for (node in l..(u-1)) {
          for (adjacent in 0..(a(node).size-1)) {
            if (d(a(node)(adjacent)) < d(node)) {
              //Console.OUT.println("node " + node + " reduce " + d(a(node)(adjacent)) + " " + d(node));
              d(node) = d(a(node)(adjacent));
              done.set(false);
            }
          }
        }
      }
      //Console.OUT.println(d.reduce((a:String, b:Int) => (a + " " + b), ""));
    }
  }
  /*
  public static def main(argv:Array[String]{self.rank==1})                         
  {
    val d = new Rail[Int](15, (i:Int) => i);
    val a = new Rail[Rail[Int]](15, (i:Int) => new Rail[Int](1, 0));
    for (i in 0..(a.size-1)) {
        a(i)(0) = i + 2;
    }
    if (d.size % 2 == 0) {
      a(d.size - 2)(0) = 1;
      a(d.size - 1)(0) = 0;
    } else {
      a(d.size - 2)(0) = 0;
      a(d.size - 1)(0) = 1;
    }


    cc(d, a);
  }
  */
    static val rand = new Random(System.nanoTime());  
    static struct Inputs
    {
        val size                :Int;                             // # of vertices in the graph
    	val nworkers     :Int;				// # of workers in this test
        val solutions     :Rail[Int];                    //  Result of the input
        val Adjacency    :Rail[Rail[Int]];                  

        def this(size: int, D: Rail[Int], A: Rail[Rail[Int]], asyncs: Int)
        {
            this.size          = size;
            this.solutions     = D;
            this.Adjacency    = A;
	    this.nworkers    = asyncs;
        }
    }

    private static def randomInput(size:Int, edges:Int)
    {
      val a = new Rail[Rail[Int]](size, (i:Int) => new Rail[Int](0));
      for (i in 0..edges) {
          val o = rand.nextInt(size);
          val r = rand.nextInt(size);
          if (o == r) continue;
          a(r) = new Rail[Int](a(r).size + 1, (i:Int) => i < a(r).size ? a(r)(i) : 0);
          a(r)(a(r).size-1) = o;
          a(o) = new Rail[Int](a(o).size + 1, (i:Int) => i < a(o).size ? a(o)(i) : 0);
          a(o)(a(o).size-1) = r;
      }
      return a;
    }

    static val INPUT_COUNT = 5;
    static val testIteration = 10;
    static val TEST_SIZE = 75000;
    static val NUM_EDGES = TEST_SIZE;

    public static def main(argv:Array[String]{self.rank==1})
    {
      if (argv.size != 1) {
          Console.ERR.println("USAGE: CCGraph <maxAsyncs>");
          return;
      }
      val asyncs = Int.parseInt(argv(0));
      var solver: CC = new CC();        
      
      val INPUTS = new Array[Inputs](0..(INPUT_COUNT - 1));

      for (i in INPUTS) {
        val graph = randomInput(TEST_SIZE, NUM_EDGES);
        val d = new Rail[Int](TEST_SIZE, (i:Int) => i);
        solver.cc(d, graph, TEST_SIZE, 1);
        INPUTS(i) = Inputs(TEST_SIZE, d, graph, asyncs);
      }
      var exectimes: double = 0;

      for (index in INPUTS) {
        exectimes = 0;
        
        try {
          for (var i:Int=0; i<testIteration; i++) {
            val D = new Rail[Int](0..(INPUTS(index).size-1));
            for(var z:Int=0; z<INPUTS(index).size; z++)
                D(z) = z;

            val start = Timer.milliTime();
            solver.cc(D, INPUTS(index).Adjacency, INPUTS(index).size, INPUTS(index).nworkers);
            val end = Timer.milliTime();
            var time_in_millis: long = end - start;

            for (y in 0..(D.size-1)) {
              if (D(y) != INPUTS(index).solutions(y))
              {
                  Console.OUT.println("\tComputed answer: INCORRECT!!!!!!!!!!!!!!!!!!!!!");
                  throw new Exception("Wrong answer");
              }
            }

            exectimes += time_in_millis;
          }

          Console.OUT.println("Avg time for test Input "+index+" is: "+exectimes / testIteration);
        }

        catch (Exception) {
            Console.OUT.println();
            Console.OUT.println("execution time " + "None ... answer was wrong.");
        }
      }
    }
}

