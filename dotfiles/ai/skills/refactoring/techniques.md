# Refactoring Techniques

The 66 refactoring techniques catalogued on refactoring.guru, grouped into 6 families. Each entry is problem -> solution. Apply in small steps, keeping tests green after each step.

## Composing Methods

- **Extract Method** - You have a code fragment that can be grouped together. -> Move this code to a separate new method (or function) and replace the old code with a call to the method.
- **Inline Method** - When a method body is more obvious than the method itself, use this technique. -> Replace calls to the method with the method's content and delete the method itself.
- **Extract Variable** - You have an expression that's hard to understand. -> Place the result of the expression or its parts in separate variables that are self-explanatory.
- **Inline Temp** - You have a temporary variable that's assigned the result of a simple expression and nothing more. -> Replace the references to the variable with the expression itself.
- **Replace Temp with Query** - You place the result of an expression in a local variable for later use in your code. -> Move the entire expression to a separate method and return the result from it. Query the method instead of using a variable. Incorporate the new method in other methods, if necessary.
- **Split Temporary Variable** - You have a local variable that's used to store various intermediate values inside a method (except for cycle variables). -> Use different variables for different values. Each variable should be responsible for only one particular thing.
- **Remove Assignments to Parameters** - Some value is assigned to a parameter inside method's body. -> Use a local variable instead of a parameter.
- **Replace Method with Method Object** - You have a long method in which the local variables are so intertwined that you can't apply Extract Method. -> Transform the method into a separate class so that the local variables become fields of the class. Then you can split the method into several methods within the same class.
- **Substitute Algorithm** - So you want to replace an existing algorithm with a new one? -> Replace the body of the method that implements the algorithm with a new algorithm.

## Moving Features between Objects

- **Move Method** - A method is used more in another class than in its own class. -> Create a new method in the class that uses the method the most, then move code from the old method to there. Turn the code of the original method into a reference to the new method in the other class or else remove it entirely.
- **Move Field** - A field is used more in another class than in its own class. -> Create a field in a new class and redirect all users of the old field to it.
- **Extract Class** - When one class does the work of two, awkwardness results. -> Instead, create a new class and place the fields and methods responsible for the relevant functionality in it.
- **Inline Class** - A class does almost nothing and isn't responsible for anything, and no additional responsibilities are planned for it. -> Move all features from the class to another one.
- **Hide Delegate** - The client gets object B from a field or method of object . Then the client calls a method of object B. -> Create a new method in class A that delegates the call to object B. Now the client doesn't know about, or depend on, class B.
- **Remove Middle Man** - A class has too many methods that simply delegate to other objects. -> Delete these methods and force the client to call the end methods directly.
- **Introduce Foreign Method** - A utility class doesn't contain the method that you need and you can't add the method to the class. -> Add the method to a client class and pass an object of the utility class to it as an argument.
- **Introduce Local Extension** - A utility class doesn't contain some methods that you need. But you can't add these methods to the class. -> Create a new class containing the methods and make it either the child or wrapper of the utility class.

## Organizing Data

- **Self Encapsulate Field** - You use direct access to private fields inside a class. -> Create a getter and setter for the field, and use only them for accessing the field.
- **Replace Data Value with Object** - A class (or group of classes) contains a data field. The field has its own behavior and associated data. -> Create a new class, place the old field and its behavior in the class, and store the object of the class in the original class.
- **Change Value to Reference** - So you have many identical instances of a single class that you need to replace with a single object. -> Convert the identical objects to a single reference object.
- **Change Reference to Value** - You have a reference object that's too small and infrequently changed to justify managing its life cycle. -> Turn it into a value object.
- **Replace Array with Object** - You have an array that contains various types of data. -> Replace the array with an object that will have separate fields for each element.
- **Duplicate Observed Data** - Is domain data stored in classes responsible for the GUI? -> Then it's a good idea to separate the data into separate classes, ensuring connection and synchronization between the domain class and the GUI.
- **Change Unidirectional Association to Bidirectional** - You have two classes that each need to use the features of the other, but the association between them is only unidirectional. -> Add the missing association to the class that needs it.
- **Change Bidirectional Association to Unidirectional** - You have a bidirectional association between classes, but one of the classes doesn't use the other's features. -> Remove the unused association.
- **Replace Magic Number with Symbolic Constant** - Your code uses a number that has a certain meaning to it. -> Replace this number with a constant that has a human-readable name explaining the meaning of the number.
- **Encapsulate Field** - You have a public field. -> Make the field private and create access methods for it.
- **Encapsulate Collection** - A class contains a collection field and a simple getter and setter for working with the collection. -> Make the getter-returned value read-only and create methods for adding/deleting elements of the collection.
- **Replace Type Code with Class** - A class has a field that contains type code. The values of this type aren't used in operator conditions and don't affect the behavior of the program. -> Create a new class and use its objects instead of the type code values.
- **Replace Type Code with Subclasses** - You have a coded type that directly affects program behavior (values of this field trigger various code in conditionals). -> Create subclasses for each value of the coded type. Then extract the relevant behaviors from the original class to these subclasses. Replace the control flow code with polymorphism.
- **Replace Type Code with State/Strategy** - You have a coded type that affects behavior but you can't use subclasses to get rid of it. -> Replace type code with a state object. If it's necessary to replace a field value with type code, another state object is "plugged in".
- **Replace Subclass with Fields** - You have subclasses differing only in their (constant-returning) methods. -> Replace the methods with fields in the parent class and delete the subclasses.

## Simplifying Conditional Expressions

- **Decompose Conditional** - You have a complex conditional (if-then/else or switch). -> Decompose the complicated parts of the conditional into separate methods: the condition, then and else.
- **Consolidate Conditional Expression** - You have multiple conditionals that lead to the same result or action. -> Consolidate all these conditionals in a single expression.
- **Consolidate Duplicate Conditional Fragments** - Identical code can be found in all branches of a conditional. -> Move the code outside of the conditional.
- **Remove Control Flag** - You have a boolean variable that acts as a control flag for multiple boolean expressions. -> Instead of the variable, use break, continue and return.
- **Replace Nested Conditional with Guard Clauses** - You have a group of nested conditionals and it's hard to determine the normal flow of code execution. -> Isolate all special checks and edge cases into separate clauses and place them before the main checks. Ideally, you should have a "flat" list of conditionals, one after the other.
- **Replace Conditional with Polymorphism** - You have a conditional that performs various actions depending on object type or properties. -> Create subclasses matching the branches of the conditional. In them, create a shared method and move code from the corresponding branch of the conditional to it. Then replace the conditional with the relevant method call. The result is that the proper implementation will be attained via polymorphism depending on the object class.
- **Introduce Null Object** - Since some methods return null instead of real objects, you have many checks for null in your code. -> Instead of null, return a null object that exhibits the default behavior.
- **Introduce Assertion** - For a portion of code to work correctly, certain conditions or values must be true. -> Replace these assumptions with specific assertion checks.

## Simplifying Method Calls

- **Rename Method** - The name of a method doesn't explain what the method does. -> Rename the method.
- **Add Parameter** - A method doesn't have enough data to perform certain actions. -> Create a new parameter to pass the necessary data.
- **Remove Parameter** - A parameter isn't used in the body of a method. -> Remove the unused parameter.
- **Separate Query from Modifier** - Do you have a method that returns a value but also changes something inside an object? -> Split the method into two separate methods. As you would expect, one of them should return the value and the other one modifies the object.
- **Parameterize Method** - Multiple methods perform similar actions that are different only in their internal values, numbers or operations. -> Combine these methods by using a parameter that will pass the necessary special value.
- **Replace Parameter with Explicit Methods** - A method is split into parts, each of which is run depending on the value of a parameter. -> Extract the individual parts of the method into their own methods and call them instead of the original method.
- **Preserve Whole Object** - You get several values from an object and then pass them as parameters to a method. -> Instead, try passing the whole object.
- **Replace Parameter with Method Call** - Calling a query method and passing its results as the parameters of another method, while that method could call the query directly. -> Instead of passing the value through a parameter, try placing a query call inside the method body.
- **Introduce Parameter Object** - Your methods contain a repeating group of parameters. -> Replace these parameters with an object.
- **Remove Setting Method** - The value of a field should be set only when it's created, and not change at any time after that. -> So remove methods that set the field's value.
- **Hide Method** - A method isn't used by other classes or is used only inside its own class hierarchy. -> Make the method private or protected.
- **Replace Constructor with Factory Method** - You have a complex constructor that does something more than just setting parameter values in object fields. -> Create a factory method and use it to replace constructor calls.
- **Replace Error Code with Exception** - A method returns a special value that indicates an error? -> Throw an exception instead.
- **Replace Exception with Test** - You throw an exception in a place where a simple test would do the job? -> Replace the exception with a condition test.

## Dealing with Generalization

- **Pull Up Field** - Two classes have the same field. -> Remove the field from subclasses and move it to the superclass.
- **Pull Up Method** - Your subclasses have methods that perform similar work. -> Make the methods identical and then move them to the relevant superclass.
- **Pull Up Constructor Body** - Your subclasses have constructors with code that's mostly identical. -> Create a superclass constructor and move the code that's the same in the subclasses to it. Call the superclass constructor in the subclass constructors.
- **Push Down Method** - Is behavior implemented in a superclass used by only one (or a few) subclasses? -> Move this behavior to the subclasses.
- **Push Down Field** - Is a field used only in a few subclasses? -> Move the field to these subclasses.
- **Extract Subclass** - A class has features that are used only in certain cases. -> Create a subclass and use it in these cases.
- **Extract Superclass** - You have two classes with common fields and methods. -> Create a shared superclass for them and move all the identical fields and methods to it.
- **Extract Interface** - Multiple clients are using the same part of a class interface. Another case: part of the interface in two classes is the same. -> Move this identical portion to its own interface.
- **Collapse Hierarchy** - You have a class hierarchy in which a subclass is practically the same as its superclass. -> Merge the subclass and superclass.
- **Form Template Method** - Your subclasses implement algorithms that contain similar steps in the same order. -> Move the algorithm structure and identical steps to a superclass, and leave implementation of the different steps in the subclasses.
- **Replace Inheritance with Delegation** - You have a subclass that uses only a portion of the methods of its superclass (or it's not possible to inherit superclass data). -> Create a field and put a superclass object in it, delegate methods to the superclass object, and get rid of inheritance.
- **Replace Delegation with Inheritance** - A class contains many simple methods that delegate to all methods of another class. -> Make the class a delegate inheritor, which makes the delegating methods unnecessary.
